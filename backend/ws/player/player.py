from dataclasses import dataclass
from typing import Callable, Union, Optional

from music_room.models import PlaySession, Playlist
from music_room.serializers import PlaySessionSerializer
from music_room.services.player import PlayerService
from ws.base import BaseConsumer, TargetsEnum, Action, Message, BasePayload, BaseEvent


class RequestPayload:
    @dataclass
    class ModifyTrack(BasePayload):
        """Modify track"""
        play_session_id: int  #: Already started play session id
        track_id: Optional[int] = None  # Optional, track id for any actions

    @dataclass
    class CreateSession(BasePayload):
        """Create Session"""
        playlist_id: int  #: Already created playlist id
        shuffle: bool = False  #: If you need create session with shuffle tracks in playlist


class ResponsePayload:
    @dataclass
    class PlayTrack(BasePayload):
        track_id: int

    @dataclass
    class PlaySession(BasePayload):
        play_session: PlaySession


class CustomTargetEnum(TargetsEnum):
    for_accessed = 'for_accessed'


def for_accessed(message: Union[Message, RequestPayload.ModifyTrack]):
    play_session = PlaySession.objects.get(id=message.play_session_id)
    if play_session.playlist.type == Playlist.Types.public:
        return True
    if message.user in play_session.playlist.access_users.values_list('id', flat=True):
        return True
    return False


def get_play_session(f: Callable):
    payload_type = RequestPayload.ModifyTrack

    def wrapper(self: BaseEvent, message: Message, payload: payload_type, *args):
        play_session = PlayerService(payload.play_session_id)
        if not play_session.play_session:
            return Action(event='error', params={'message': 'Session not found'}, system=message.system.to_data())
        return f(self, message, payload, play_session, *args)

    return wrapper


def restore_play_session(f: Callable):
    def wrapper(self):
        play_session = PlaySession.objects.filter(author=self.get_user()).first()
        return f(self, play_session)

    return wrapper


def only_for_author(f: Callable):
    payload_type = RequestPayload.ModifyTrack

    def wrapper(self: BaseEvent, message: Message, payload: payload_type, play_session: PlayerService, *args):
        if message.user != play_session.play_session.author:
            return Action(
                event='error',
                params={'message': 'Only session author cat navigate player'},
                system=message.system.to_data()
            )
        return f(self, message, payload, play_session, *args)

    return wrapper


def check_play_session(f: Callable):
    payload_type = RequestPayload.ModifyTrack

    def wrapper(self: BaseEvent, message: Message, payload: payload_type, *args):
        play_session = PlayerService(payload.play_session_id)
        if not play_session.play_session:
            return
        return f(self, message, payload, *args)

    return wrapper


class PlayerConsumer(BaseConsumer):
    broadcast_group = 'player'
    authed = True
    custom_target_resolver = {CustomTargetEnum.for_accessed: for_accessed}

    @restore_play_session
    def connect(self, play_session: PlaySession):
        super(PlayerConsumer, self).connect()
        self.send_json(ResponsePayload.PlaySession(
            play_session=PlaySessionSerializer(play_session).data if play_session else None
        ).to_data())

    class CreateSession(BaseEvent):
        """
        Create session
        """
        request_payload_type = RequestPayload.CreateSession
        target = TargetsEnum.only_for_initiator

        def action_for_initiator(self, message: Message, payload: request_payload_type):
            play_session = PlaySession.objects.create(playlist_id=payload.playlist_id, author=message.initiator_user)
            if payload.shuffle:
                play_session = PlayerService(play_session)
                play_session.shuffle()
                play_session = play_session.play_session
            return Action(
                event='session_created',
                params=ResponsePayload.PlaySession(play_session=PlaySessionSerializer(play_session).data).to_data(),
                system=self.event['system']
            )

    class Session(BaseEvent):
        request_payload_type = RequestPayload.ModifyTrack
        target = CustomTargetEnum.for_accessed

        @check_play_session
        def action_for_target(self, message: Message, payload: request_payload_type):
            action = Action(event='session_changed', system=self.event['system'])
            action.params = ResponsePayload.PlaySession(
                play_session=PlaySessionSerializer(
                    PlayerService(payload.play_session_id).play_session).data).to_data(),
            return action

        @check_play_session
        def action_for_initiator(self, message: Message, payload: request_payload_type):
            action = Action(event='session_changed', system=self.event['system'])
            action.params = ResponsePayload.PlaySession(
                play_session=PlaySessionSerializer(
                    PlayerService(payload.play_session_id).play_session).data).to_data(),
            return action

    class PlayTrack(Session, BaseEvent):
        request_payload_type = RequestPayload.ModifyTrack

        @get_play_session
        @only_for_author
        def before_send(self, message: Message, payload: request_payload_type, play_session: PlayerService):
            play_session.play_track(play_session.current_track)

    class PlayNextTrack(Session, BaseEvent):
        request_payload_type = RequestPayload.ModifyTrack

        @get_play_session
        @only_for_author
        def before_send(self, message: Message, payload: request_payload_type, play_session: PlayerService):
            play_session.play_next()

    class PlayPreviousTrack(Session, BaseEvent):
        request_payload_type = RequestPayload.ModifyTrack

        @get_play_session
        @only_for_author
        def before_send(self, message: Message, payload: request_payload_type, play_session: PlayerService):
            play_session.play_previous()

    class Shuffle(Session, BaseEvent):
        request_payload_type = RequestPayload.ModifyTrack

        @get_play_session
        @only_for_author
        def before_send(self, message: Message, payload: request_payload_type, play_session: PlayerService):
            play_session.shuffle()

    class PauseTrack(Session, BaseEvent):
        request_payload_type = RequestPayload.ModifyTrack

        @get_play_session
        @only_for_author
        def before_send(self, message: Message, payload: request_payload_type, play_session: PlayerService):
            play_session.pause_track()

    class ResumeTrack(Session, BaseEvent):
        request_payload_type = RequestPayload.ModifyTrack

        @get_play_session
        @only_for_author
        def before_send(self, message: Message, payload: request_payload_type, play_session: PlayerService):
            play_session.resume_track()

    class StopTrack(Session, BaseEvent):
        request_payload_type = RequestPayload.ModifyTrack

        @get_play_session
        @only_for_author
        def before_send(self, message: Message, payload: request_payload_type, play_session: PlayerService):
            play_session.stop_track()
