from typing import Callable

from django.contrib.auth import get_user_model

from music_room.models import Event, EventAccess

User = get_user_model()


class EventService:
    class Decorators:
        @staticmethod
        def lookup_user(f: Callable, *args):
            def wrapper(self, user, *args):
                if isinstance(user, int):
                    try:
                        user = User.objects.get(id=user)
                    except User.DoesNotExist:
                        user = None
                return f(self, user, *args)

            return wrapper

        @staticmethod
        def lookup_event(f: Callable):
            def wrapper(self, event, *args):
                if isinstance(event, int):
                    try:
                        event = Event.objects.get(id=event)
                    except Event.DoesNotExist:
                        event = None
                return f(self, event, *args)

            return wrapper

    @Decorators.lookup_event
    def __init__(self, event: [int, Event]):
        self.event: Event = event

    @Decorators.lookup_user
    def invite_user(self, user: User):
        if self.event.author != user and user:
            self.event.event_access_users.filter(user=user).delete()
            self.event.event_access_users.add(EventAccess.objects.create(
                user=user,
                access_mode=EventAccess.AccessMode.guest,
                event=self.event
            ))

    @Decorators.lookup_user
    def revoke_user(self, user: User):
        if self.event.author != user and user:
            self.event.event_access_users.filter(user=user).delete()

    def change_user_access_mode(self, user_id: int, access_mode: EventAccess.AccessMode = None):
        try:
            user = User.objects.get(id=user_id)
        except Exception:
            user = None
        if self.event.author != user and user:
            access_user: EventAccess = self.event.event_access_users.filter(user=user).first()
            access_user.access_mode = access_mode
            access_user.save()

    def change_access_type(self, access_type: Event.AccessTypes):
        self.event.access_type = access_type
        self.event.save()

    def change(self, name: str = None, access_type: [str, Event.AccessTypes] = None):
        if not name:
            name = self.event.name
        if not access_type:
            access_type = self.event.access_type
        self.event.name = name
        self.event.access_type = access_type
        self.event.save()
