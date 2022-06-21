import dataclasses
import json
from dataclasses import dataclass
from typing import Any, Optional
from django.contrib.auth import get_user_model
from django.core.cache import cache

User = get_user_model()


class BasePayload:
    def __init__(self, **kwargs):
        self.__dict__.update(kwargs)

    def __str__(self):
        return f'Payload Object: {json.dumps(self.to_data())}'

    def to_data(self, *args):
        if args:
            return self.__dict__
        return self.__dict__

    def __repr__(self):
        return self.to_data()


class ResponsePayload:
    """List of response payload signatures"""

    @dataclass
    class ActionNotExist(BasePayload):
        message: str = 'Action not exist'  #: Error message

    @dataclass
    class PayloadSignatureWrong(BasePayload):
        required: str  #: Hint about missing signature
        message: str = 'Payload signature wrong'  #: Error message

    @dataclass
    class ActionSignatureWrong(BasePayload):
        unexpected: str  #: Hint about unexpected signature
        message: str = 'Action signature wrong'  #: Error message

    @dataclass
    class RecipientNotExist(BasePayload):
        message: str = 'Recipient not exist'  #: Error message

    @dataclass
    class RecipientIsMe(BasePayload):
        message: str = 'You cannot be the recipient'  #: Error message

    @dataclass
    class Error(BasePayload):
        message: str  #: Error message


class ActionsEnum:
    """List of existed actions"""
    error = 'error'  #: :func:`BaseConsumer.error`


@dataclass
class ActionSystem:
    initiator_channel: str = None  #: Action initiator channel name
    initiator_user_id: int = None  #: Action initiator user id
    action_id: str = None

    def to_data(self):
        return {
            'initiator_channel': self.initiator_channel,
            'initiator_user_id': self.initiator_user_id,
            'action_id': self.action_id,
        }


@dataclass
class Action:
    """Action signature for request and response"""
    event: str  #: Action's name
    system: Optional[ActionSystem] = None  #: System event information
    payload: Any = dataclasses.field(default_factory=dict)  #: Action's payload

    def __str__(self, to_json=True):
        data = ActionData(
            type=self.event,
            payload=self.payload,
            system=self.system
        ).to_data()
        if to_json:
            return json.dumps(data)
        return data

    def to_system_data(self):
        return self.__str__(to_json=False)

    def to_data(self, to_json=False, pop_system=False):
        data = {
            'event': self.event,
            'payload': self.payload,
            'system': self.system.to_data() if isinstance(self.system, ActionSystem) else self.system
        }
        if pop_system:
            data.pop('system')
        if to_json:
            data = json.dumps(data, default=lambda o: o.__dict__)
        return data

    def to_json(self):
        return self.to_data(to_json=True)


@dataclass
class ActionData:
    type: str  #: Handler's name
    payload: Any  #: Handler's payload
    system: ActionSystem  #: System handler information

    def to_data(self):
        return {
            'type': self.type,
            'payload': self.payload,
            'system': self.system.to_data() if isinstance(self.system, ActionSystem) else self.system
        }


@dataclass
class MessageSystem:
    initiator_channel: str  #: Initiator channel name
    receiver_channel: str  #: Receiver channel name
    initiator_user_id: int  #: Initiator user id
    action_id: str  #: Action id

    def to_data(self):
        return {
            'initiator_channel': self.initiator_channel,
            'initiator_user_id': self.initiator_user_id,
            'action_id': self.action_id,
        }


class TargetsEnum:
    """Broadcast targets"""
    for_all = 'for_all'  #: For all users in broadcast group
    for_user = 'for_user'  #: For specific user (lookup by specific key)
    only_for_initiator = 'only_for_initiator'  #: For initiator user only


class Message:
    user: User  #: User who receive message
    system: MessageSystem  #: System message information
    target: TargetsEnum  #: Target for broadcast
    to_user_id: int = None  #: Message target user id
    to_username: str = None  #: Message target user username
    custom_target_resolver: dict  #: Custom target resolver

    def __init__(self, **kwargs):
        self.__dict__.update(kwargs)

    @property
    def is_target(self):
        if self.target == TargetsEnum.only_for_initiator and self.is_initiator:
            return True
        if self.is_initiator:
            return False
        if self.target == TargetsEnum.for_all:
            return True
        if self.target == TargetsEnum.for_user:
            return self.user.id == self.to_user_id or self.user.username == self.to_username
        return self.custom_target_resolver.get(self.target, lambda _: False)(self)

    @property
    def is_initiator(self):
        return self.system.initiator_channel == self.system.receiver_channel

    @property
    def initiator_user(self) -> User:
        return User.objects.get(id=self.system.initiator_user_id)

    @property
    def target_user(self) -> User:
        # TODO Add extend lookup logic for child Consumer
        if self.to_user_id:
            return User.objects.filter(id=self.to_user_id).first()
        if self.to_username:
            return User.objects.filter(username=self.to_username).first()

    @property
    def before_send_activated(self):
        result = cache.get(f'{self.system.action_id, self.system.initiator_channel}')
        return result

    def before_send_activate(self):
        cache.set(f'{self.system.action_id, self.system.initiator_channel}', True, 180)

    def before_send_drop(self):
        cache.delete(f'{self.system.action_id, self.system.initiator_channel}')
