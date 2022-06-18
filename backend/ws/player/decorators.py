from typing import Callable

from music_room.models import PlayerSession, Playlist
from music_room.services import PlayerService
from ws.base import BaseEvent, Action, Message


def get_player_session(f: Callable):
    from ws.player.player import RequestPayload

    payload_type = RequestPayload.ModifyTrack

    def wrapper(self: BaseEvent, message: Message, payload: payload_type, *args):
        player_session = PlayerService(payload.player_session_id)
        if not player_session.player_session:
            return Action(event='error', payload={'message': 'Session not found'}, system=message.system.to_data())
        return f(self, message, payload, player_session, *args)

    return wrapper


def restore_player_session(f: Callable):
    def wrapper(self):
        player_session = PlayerSession.objects.filter(author=self.get_user()).first()
        return f(self, player_session)

    return wrapper


def only_for_author(f: Callable):
    from ws.player.player import RequestPayload

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
    from ws.player.player import RequestPayload

    payload_type = RequestPayload.ModifyTrack

    def wrapper(self: BaseEvent, message: Message, payload: payload_type, *args):
        player_session = PlayerService(payload.player_session_id)
        if not player_session.player_session:
            return
        return f(self, message, payload, *args)

    return wrapper


def get_playlist(f: Callable):
    from ws.player.player import RequestPayload

    payload_type = RequestPayload.CreateSession

    def wrapper(self: BaseEvent, message: Message, payload: payload_type, *args):
        playlist = Playlist.objects.filter(id=payload.playlist_id, author=self.consumer.get_user()).first()
        if not playlist:
            return Action(event='error', payload={'message': 'Playlist not found'}, system=message.system.to_data())
        return f(self, message, payload, playlist, *args)

    return wrapper
