from dataclasses import dataclass
from typing import Callable, Union

from music_room.models import PlaySession, Playlist
from music_room.serializers import PlaySessionSerializer
from music_room.service import Player
from ws.base import BaseConsumer, TargetsEnum, Action, Message, BasePayload


class RequestPayload:
    @dataclass
    class PlayTrack(BasePayload):
        play_session_id: int
        track_id: int = None

    @dataclass
    class CreateSession(BasePayload):
        playlist_id: int
        shuffle: bool = False


class ResponsePayload:
    class PlayTrack(BasePayload):
        track_id: int


class CustomTargetEnum(TargetsEnum):
    for_accessed = 'for_accessed'


def for_accessed(message: Union[Message, RequestPayload.PlayTrack]):
    play_session = PlaySession.objects.get(id=message.play_session_id)
    if play_session.playlist.type == Playlist.Types.public:
        return True
    if message.user in play_session.playlist.access_users.values_list('id', flat=True):
        return True
    return False


def get_player(f: Callable):
    def wrapper(*args):
        message: Message = args[0]
        payload: RequestPayload.PlayTrack = args[1]
        player = Player(payload.play_session_id)
        if not player.play_session:
            return Action(event='error', params={'message': 'Session not found'}, system=message.system.to_data())
        return f(*args, player)

    return wrapper


def only_for_author(f: Callable):
    def wrapper(*args):
        message: Message = args[0]
        payload: RequestPayload.PlayTrack = args[1]
        player: Player = args[2]

        if message.user != player.play_session.author:
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
        payload: RequestPayload.PlayTrack = args[1]
        player = Player(payload.play_session_id)
        if not player.play_session:
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
            payload = RequestPayload.CreateSession(**payload.to_data())
            if payload.shuffle:
                player = Player(play_session)
                player.shuffle()
                play_session = player.play_session
            return Action(
                event='session_created',
                params={'session': PlaySessionSerializer(play_session).data},
                system=event['system']
            )

        self.send_broadcast(
            event,
            action_for_initiator=action_for_initiator,
            target=TargetsEnum.only_for_initiator
        )

    def session(self, event, before_send: Callable = None):
        request_payload_type = RequestPayload.PlayTrack
        action = Action(event='session_changed', system=event['system'])

        @check_play_session
        def action_for_target(message: Message, payload: request_payload_type):
            action.params = {'session': PlaySessionSerializer(Player(payload.play_session_id).play_session).data}
            return action

        @check_play_session
        def action_for_initiator(message: Message, payload: request_payload_type):
            action.params = {'session': PlaySessionSerializer(Player(payload.play_session_id).play_session).data}
            return action

        self.send_broadcast(
            event,
            action_for_target=action_for_target,
            action_for_initiator=action_for_initiator,
            before_send=before_send,
            target=CustomTargetEnum.for_accessed
        )

    def play_track(self, event):
        @get_player
        @only_for_author
        def before_send(message: Message, payload: RequestPayload.PlayTrack, player: Player):
            player.play_track(payload.track_id)

        self.session(event, before_send)

    def play_next_track(self, event):
        @get_player
        @only_for_author
        def before_send(message: Message, payload: RequestPayload.PlayTrack, player: Player):
            player.play_next()

        self.session(event, before_send)

    def play_previous_track(self, event):
        @get_player
        @only_for_author
        def before_send(message: Message, payload: RequestPayload.PlayTrack, player: Player):
            player.play_previous()

        self.session(event, before_send)

    def shuffle(self, event):
        @get_player
        @only_for_author
        def before_send(message: Message, payload: RequestPayload.PlayTrack, player: Player):
            player.shuffle()

        self.session(event, before_send)

    def pause_track(self, event):
        @get_player
        @only_for_author
        def before_send(message: Message, payload: RequestPayload.PlayTrack, player: Player):
            player.pause_track()

        self.session(event, before_send)

    def resume_track(self, event):
        @get_player
        @only_for_author
        def before_send(message: Message, payload: RequestPayload.PlayTrack, player: Player):
            player.resume_track()

        self.session(event, before_send)

    def stop_track(self, event):
        @get_player
        @only_for_author
        def before_send(message: Message, payload: RequestPayload.PlayTrack, player: Player):
            player.stop_track()

        self.session(event, before_send)
