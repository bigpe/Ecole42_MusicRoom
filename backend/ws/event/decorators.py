from typing import Callable

from django.db.models import Q

from music_room.models import Event, Playlist, EventAccess
from ws.base import BaseEvent, Message
from ws.utils import ActionRef as Action


def get_event_from_path(f: Callable):
    def wrapper(self):
        try:
            event = Event.objects.get(id=int(self.scope['url_route']['kwargs']['event_id']))
            return f(self, event)
        except Event.DoesNotExist:
            self.close()
            self.disconnect(1000)
            return

    return wrapper


def get_event(f: Callable):
    def wrapper(self: BaseEvent, message: Message, payload, *args):
        from .consumers import EventRetrieveConsumer
        self.consumer: EventRetrieveConsumer

        try:
            playlist = Event.objects.get(id=self.consumer.event_id)
            return f(self, message, payload, playlist, *args)
        except Event.DoesNotExist:
            return Action(event='error', payload={'message': 'Event not found'}, system=message.system.to_data())

    return wrapper


def only_for_accessed(f: Callable):
    def wrapper(self, event: Event):
        from ws.event.consumers import EventRetrieveConsumer
        self: EventRetrieveConsumer

        user = self.get_user()

        if user not in event.event_access_users.all():
            if user != event.author:
                self.close()
                self.disconnect(1000)
                return
        return f(self, event)

    return wrapper


def get_playlist(f: Callable):
    def wrapper(self: BaseEvent, message: Message, payload, *args):
        from .consumers import EventRetrieveConsumer
        self.consumer: EventRetrieveConsumer

        event = Event.objects.get(id=self.consumer.event_id)
        playlist = Playlist.objects.get(id=event.playlist.id)
        return f(self, message, payload, playlist, *args)

    return wrapper


def only_for_staff(f: Callable):
    def wrapper(self: BaseEvent, message: Message, payload, event: Event, *args):
        from .consumers import EventRetrieveConsumer
        self.consumer: EventRetrieveConsumer

        user = self.consumer.get_user()
        access_roles = [EventAccess.AccessMode.moderator, EventAccess.AccessMode.administrator]
        access_allowed = check_access(event, user, access_roles)

        if not access_allowed:
            return Action(
                event='error',
                payload={'message': 'Access denied'},
                system=message.system.to_data()
            )
        return f(self, message, payload, event, *args)

    return wrapper


def only_for_administrator(f: Callable):
    def wrapper(self: BaseEvent, message: Message, payload, event: Event, *args):
        from .consumers import EventRetrieveConsumer
        self.consumer: EventRetrieveConsumer

        user = self.consumer.get_user()
        access_roles = [EventAccess.AccessMode.administrator]
        access_allowed = check_access(event, user, access_roles)

        if not access_allowed:
            return Action(
                event='error',
                payload={'message': 'Access denied'},
                system=message.system.to_data()
            )
        return f(self, message, payload, event, *args)

    return wrapper


def only_for_moderator(f: Callable):
    def wrapper(self: BaseEvent, message: Message, payload, event: Event, *args):
        from .consumers import EventRetrieveConsumer
        self.consumer: EventRetrieveConsumer

        user = self.consumer.get_user()
        access_roles = [EventAccess.AccessMode.moderator]
        access_allowed = check_access(event, user, access_roles)

        if not access_allowed:
            return Action(
                event='error',
                payload={'message': 'Access denied'},
                system=message.system.to_data()
            )
        return f(self, message, payload, event, *args)

    return wrapper


def check_access(event, user, access_roles: list):
    user_access = event.event_access_users.filter(user=user).first()
    user_access_mode = EventAccess.AccessMode.guest
    if not user_access and event.author == user:
        user_access_mode = EventAccess.AccessMode.administrator

    if user_access_mode not in access_roles:
        return False
    return True
