from typing import Callable

from django.db.models import Q

from music_room.models import PlayerSession, Playlist
from music_room.services import PlayerService
from ws.base import BaseEvent, BaseConsumer, Message
from ws.utils import ActionRef as Action


def get_player_service(f: Callable):
    from ws.player.consumers import RequestPayload

    payload_type = RequestPayload.ModifyTrack

    def wrapper(self: BaseEvent, message: Message, payload: payload_type, *args):
        player_session = PlayerService(payload.player_session_id)
        if not player_session.player_session:
            return Action(event='error', payload={'message': 'Session not found'}, system=message.system.to_data())
        return f(self, message, payload, player_session, *args)

    return wrapper


def restore_player_session(f: Callable):
    def wrapper(self: [BaseConsumer, BaseEvent], *args):
        consumer: BaseConsumer = self if isinstance(self, BaseConsumer) else self.consumer

        if consumer.get_user().is_anonymous:
            return None

        player_session = PlayerSession.objects.filter(author=consumer.get_user()).first()
        if isinstance(self, BaseEvent):
            return f(self, *args, player_session)
        return f(self, player_session)

    return wrapper


def only_for_author(f: Callable):
    from ws.player.consumers import RequestPayload

    payload_type = RequestPayload.ModifyTrack

    def wrapper(self: BaseEvent, message: Message, payload: payload_type, player_session: PlayerService, *args):
        if message.user != player_session.player_session.author:
            return Action(
                event='error',
                payload={'message': 'Only session author cat navigate player'},
                system=message.system.to_data()
            )
        return f(self, message, payload, player_session, *args)

    return wrapper


def check_player_session(f: Callable):
    from ws.player.consumers import RequestPayload

    payload_type = RequestPayload.ModifyTrack

    def wrapper(self: BaseEvent, message: Message, payload: payload_type, *args):
        player_session = PlayerService(payload.player_session_id)
        if not player_session.player_session:
            return
        return f(self, message, payload, *args)

    return wrapper


def get_playlist(f: Callable):
    from ws.player.consumers import RequestPayload

    payload_type = RequestPayload.CreateSession

    def wrapper(self: BaseEvent, message: Message, payload: payload_type, *args):
        # Filter self own playlists or public playlists or if user in accessed for this playlist
        playlist = Playlist.objects.filter(
            Q(author=self.consumer.get_user()) |
            Q(type=Playlist.AccessTypes.public) |
            Q(playlist_access_users__user__in=[self.consumer.get_user()]),
            id=payload.playlist_id
        ).first()
        if not playlist:
            return Action(event='error', payload={'message': 'Playlist not found'}, system=message.system.to_data())
        return f(self, message, payload, playlist, *args)

    return wrapper
