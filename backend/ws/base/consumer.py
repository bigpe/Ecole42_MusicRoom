"""
Websocket: Base
====================================
Base websocket consumer
"""

from __future__ import annotations
import uuid
from typing import Callable

from asgiref.sync import async_to_sync
from channels.consumer import get_handler_name
from channels.db import database_sync_to_async
from channels.generic.websocket import JsonWebsocketConsumer
from django.contrib.auth.models import AnonymousUser
from django.core.cache import cache

from .decoratos import auth, safe
from .signatures import ResponsePayload, BasePayload, Action, TargetsEnum, Message, ActionSystem, \
    MessageSystem
from .utils import camel_to_snake, user_cache_key, camel_to_dot, dot_to_camel

from django.contrib.auth import get_user_model

User = get_user_model()


class BaseEvent:
    request_payload_type = BasePayload
    response_payload_type = BasePayload
    response_payload_type_initiator = BasePayload
    response_payload_type_target = BasePayload
    target = TargetsEnum.for_all
    hidden = False
    event_name = None
    consumer = None

    def __init__(self, consumer: BaseConsumer, event=None, payload: BasePayload = None, trigger=True):
        payload = payload if payload else BasePayload()
        self.event_name = camel_to_dot(self.__class__.__name__)
        self.consumer = consumer if consumer else self.consumer
        if not self.consumer:
            print('Provide consumer instance for direct call event')
            return

        if not event:
            self.hidden = False
            event = {
                'type': self.event_name,
                'payload': {dot_to_camel(self.event_name): payload.to_data()},
                'system': self.consumer.get_systems().to_data()
            }

        self.event = event

        if trigger:
            if self.hidden:
                self.consumer.Error(consumer=self.consumer, payload=ResponsePayload.ActionNotExist())
                return
            self.consumer.send_broadcast(
                event,
                action_for_target=self.action_for_target,
                action_for_initiator=self.action_for_initiator,
                target=self.target,
                before_send=self.before_send,
                payload_type=self.request_payload_type
            )

    def before_send(self, message: Message, payload: request_payload_type):
        ...

    def action_for_initiator(self, message: Message, payload: request_payload_type):
        ...

    def action_for_target(self, message: Message, payload: request_payload_type):
        ...

    def __call__(self, payload: [dict, BasePayload]) -> [Action, None]:
        if isinstance(payload, BasePayload):
            payload = payload.to_data()
        event = self.event
        return Action(event=event.pop('type'), system=event.pop('system'), payload=payload)


class BaseConsumer(JsonWebsocketConsumer):
    broadcast_group = None
    authed = True
    custom_target_resolver = {}

    def __init__(self):
        super(BaseConsumer, self).__init__()
        attributes = list(filter(lambda attr: not attr.startswith('_') and not attr.startswith('__'), dir(self)))
        classes = list(filter(lambda cls: hasattr(getattr(self, cls), '__base__'), attributes))
        events = list(filter(lambda e: issubclass(getattr(self, e), BaseEvent), classes))
        for event in events:
            event_class = getattr(self, event)
            hidden = getattr(event_class, 'hidden', False)
            if not hidden:
                setattr(self, camel_to_snake(event), event_class)

    @auth
    def connect(self):
        self.cache_system()
        self.join_group(self.broadcast_group)
        self.after_connect()

    @database_sync_to_async
    def dispatch(self, message):
        handler: Callable = getattr(self, get_handler_name(message), None)
        if hasattr(handler, 'hidden'):
            handler: BaseEvent.__class__
            handler(consumer=self, event=message)
        else:
            handler(message)

    def after_connect(self):
        ...

    def before_disconnect(self):
        ...

    def disconnect(self, code):
        self.before_disconnect()

    def send_json(self, content, close=False):
        if 'system' in content:
            content.pop('system')
        super(BaseConsumer, self).send_json(content, close)

    def cache_system(self):
        if not self.get_user().is_anonymous:
            cache.set(user_cache_key(self.get_user()), self.get_systems().to_data(), 40 * 60)

    def get_user(self, user_id: int = None) -> User:
        return User.objects.get(id=user_id) if user_id else self.scope.get('user', AnonymousUser())

    def join_group(self, group_name: str):
        if group_name:
            async_to_sync(self.channel_layer.group_add)(group_name, self.channel_name)

    def leave_group(self, group_name: str):
        if group_name:
            async_to_sync(self.channel_layer.group_discard)(group_name, self.channel_name)

    def get_systems(self) -> ActionSystem:
        return ActionSystem(
            initiator_channel=self.channel_name,
            initiator_user_id=self.scope['user'].id,
            action_id=str(uuid.uuid4())
        )

    @safe
    def receive(self, *arg, **kwargs):
        super().receive(*arg, **kwargs)

    @safe
    def send(self, *arg, **kwargs):
        super().send(*arg, **kwargs)

    def receive_json(self, content, **kwargs):
        if self.broadcast_group:
            action, error = self.check_signature(lambda: Action(**content, system=self.get_systems()))
            if error:
                return
            if action:
                action_handler = getattr(self, get_handler_name(action.to_system_data()), None)
                if action_handler:
                    action_handler.consumer = self
                if not action_handler:
                    self.Error(payload=ResponsePayload.ActionNotExist(), consumer=self)
                    return
                async_to_sync(self.channel_layer.group_send)(self.broadcast_group, action.to_system_data())

    def send_to_group(self, action: Action, group_name: str = None):
        async_to_sync(
            self.channel_layer.group_send
        )(self.broadcast_group if not group_name else group_name, action.to_system_data())

    def check_signature(self, f: Callable):
        error = False
        data = None
        try:
            data = f()
        except TypeError as e:
            if ' missing ' in str(e):
                required = str(e).split('argument: ')[1].strip().replace("'", '')
                self.Error(payload=ResponsePayload.PayloadSignatureWrong(required=required), consumer=self)
                error = True
            if ' unexpected ' in str(e):
                unexpected = str(e).split('argument')[1].strip().replace("'", '')
                self.Error(payload=ResponsePayload.ActionSignatureWrong(unexpected=unexpected), consumer=self)
                error = True
        return data, error

    def parse_payload(self, event, payload_type: BasePayload()):
        payload = BasePayload(**event['payload'])
        error = False
        if payload_type:
            payload, error = self.check_signature(lambda: payload_type(**payload.to_data()))
        return payload, error

    @safe
    def send_broadcast(self, event, action_for_target: Callable = None, action_for_initiator: Callable = None,
                       target=TargetsEnum.for_all, before_send: Callable = None,
                       system_before_send: Callable = None, payload_type: BasePayload() = None):

        payload, error = self.parse_payload(event, payload_type)
        if error:
            return

        message = Message(
            **payload.to_data(),
            system=MessageSystem(
                **ActionSystem(**event['system']).to_data(),
                receiver_channel=self.channel_name
            ),
            user=self.scope['user'],
            target=target,
            custom_target_resolver=self.custom_target_resolver
        )

        if system_before_send:
            system_before_send()

        if (message.target == TargetsEnum.for_user and not message.target_user) and message.is_initiator:
            self.Error(payload=ResponsePayload.RecipientNotExist(), consumer=self)
            return  # Interrupt action for initiator and action for target if recipient not found

        def before():
            if before_send and not message.before_send_activated:
                before_send(message, payload)
                message.before_send_activate()
                return True
            return False

        if message.is_initiator and action_for_initiator:
            activated = before()
            action: Action = action_for_initiator(message, payload)
            if action:
                self.send_json(content=action.to_data())
            if message.before_send_activated and not activated:
                message.before_send_drop()

        if message.is_target and action_for_target:
            activated = before()
            action: Action = action_for_target(message, payload)
            if action:
                self.send_json(content=action.to_data())
            if message.before_send_activated and not activated:
                message.before_send_drop()

    class Error(BaseEvent):
        """Show error message"""
        request_payload_type = ResponsePayload.Error

        def action_for_initiator(self, message: Message, payload: request_payload_type):
            return self(payload=ResponsePayload.Error(message=payload.message))
