from dataclasses import dataclass
from typing import Callable, Union

from music_room.models import PlaySession, Playlist
from music_room.serializers import PlaySessionSerializer
from music_room.services.player import PlayerService
from ws.base import BaseConsumer, TargetsEnum, Action, Message, BasePayload


class RequestPayload:
    @dataclass
    class ModifyTrack(BasePayload):
        play_session_id: int
        track_id: int = None

    @dataclass
    class CreateSession(BasePayload):
        playlist_id: int
        shuffle: bool = False


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
    def wrapper(*args):
        message: Message = args[0]
        payload: RequestPayload.ModifyTrack = args[1]
        play_session = PlayerService(payload.play_session_id)
        if not play_session.play_session:
            return Action(event='error', params={'message': 'Session not found'}, system=message.system.to_data())
        return f(*args, play_session)

    return wrapper


def only_for_author(f: Callable):
    def wrapper(*args):
        message: Message = args[0]
        payload: RequestPayload.ModifyTrack = args[1]
        play_session: PlayerService = args[2]

        if message.user != play_session.play_session.author:
            return Action(
                event='error',
                params={'message': 'Only session author cat navigate player'},
                system=message.system.to_data()
            )
        return f(*args)

    return wrapper


def check_play_session(f: Callable):
    def wrapper(*args):
        message: Message = args[0]
        payload: RequestPayload.ModifyTrack = args[1]
        play_session = PlayerService(payload.play_session_id)
        if not play_session.play_session:
            return
        return f(*args)

    return wrapper


class PlayerConsumer(BaseConsumer):
    broadcast_group = 'player'
    authed = True
    custom_target_resolver = {CustomTargetEnum.for_accessed: for_accessed}

    def create_session(self, event):
        def action_for_initiator(message: Message, payload: RequestPayload.CreateSession):
            play_session = PlaySession.objects.create(playlist_id=payload.playlist_id, author=message.initiator_user)
            if payload.shuffle:
                play_session = PlayerService(play_session)
                play_session.shuffle()
                play_session = play_session.play_session
            return Action(
                event='session_created',
                params=ResponsePayload.PlaySession(play_session=PlaySessionSerializer(play_session).data).to_data(),
                system=event['system']
            )

        self.send_broadcast(
            event,
            action_for_initiator=action_for_initiator,
            target=TargetsEnum.only_for_initiator,
            payload_type=RequestPayload.CreateSession,
        )

    def session(self, event, before_send: Callable = None):
        request_payload_type = RequestPayload.ModifyTrack
        action = Action(event='session_changed', system=event['system'])

        @check_play_session
        def action_for_target(message: Message, payload: request_payload_type):
            action.params = ResponsePayload.PlaySession(
                play_session=PlaySessionSerializer(
                    PlayerService(payload.play_session_id).play_session).data).to_data(),
            return action

        @check_play_session
        def action_for_initiator(message: Message, payload: request_payload_type):
            action.params = ResponsePayload.PlaySession(
                play_session=PlaySessionSerializer(
                    PlayerService(payload.play_session_id).play_session).data).to_data(),
            return action

        self.send_broadcast(
            event,
            action_for_target=action_for_target,
            action_for_initiator=action_for_initiator,
            before_send=before_send,
            target=CustomTargetEnum.for_accessed
        )

    def play_track(self, event):
        @get_play_session
        @only_for_author
        def before_send(message: Message, payload: RequestPayload.ModifyTrack, play_session: PlayerService):
            play_session.play_track(payload.track_id)

        self.session(event, before_send)

    def play_next_track(self, event):
        @get_play_session
        @only_for_author
        def before_send(message: Message, payload: RequestPayload.ModifyTrack, play_session: PlayerService):
            play_session.play_next()

        self.session(event, before_send)

    def play_previous_track(self, event):
        @get_play_session
        @only_for_author
        def before_send(message: Message, payload: RequestPayload.ModifyTrack, play_session: PlayerService):
            play_session.play_previous()

        self.session(event, before_send)

    def shuffle(self, event):
        @get_play_session
        @only_for_author
        def before_send(message: Message, payload: RequestPayload.ModifyTrack, play_session: PlayerService):
            play_session.shuffle()

        self.session(event, before_send)

    def pause_track(self, event):
        @get_play_session
        @only_for_author
        def before_send(message: Message, payload: RequestPayload.ModifyTrack, play_session: PlayerService):
            play_session.pause_track()

        self.session(event, before_send)

    def resume_track(self, event):
        @get_play_session
        @only_for_author
        def before_send(message: Message, payload: RequestPayload.ModifyTrack, play_session: PlayerService):
            play_session.resume_track()

        self.session(event, before_send)

    def stop_track(self, event):
        @get_play_session
        @only_for_author
        def before_send(message: Message, payload: RequestPayload.ModifyTrack, play_session: PlayerService):
            play_session.stop_track()

        self.session(event, before_send)
