from dataclasses import dataclass
from typing import Callable, Union

from music_room.models import PlaySession, Playlist
from music_room.serializers import PlaySessionSerializer
from music_room.service import Player
from ws.base import BaseConsumer, TargetsEnum, Action, Message, BasePayload


@dataclass
class RequestPayload:
    class PlayTrack(BasePayload):
        play_session_id: int
        track_id: int = None
        next: bool = False
        previous: bool = False


@dataclass
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


class PlayerConsumer(BaseConsumer):
    broadcast_group = 'player'
    authed = True
    custom_target_resolver = {CustomTargetEnum.for_accessed: for_accessed}

    def session(self, event, before_send: Callable = None):
        request_payload_type = RequestPayload.PlayTrack
        action = Action(event='session_change', system=event['system'])

        def action_for_target(message: Message, payload: request_payload_type):
            action.params = {'session': PlaySessionSerializer(Player(payload.play_session_id).play_session).data}
            return action

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
        def before_send(message: Message, payload: RequestPayload.PlayTrack):
            player = Player(payload.play_session_id)
            player.play_track(payload.track_id)

        self.session(event, before_send)

    def play_next_track(self, event):
        def before_send(message: Message, payload: RequestPayload.PlayTrack):
            player = Player(payload.play_session_id)
            player.play_next()

        self.session(event, before_send)

    def play_previous_track(self, event):
        def before_send(message: Message, payload: RequestPayload.PlayTrack):
            player = Player(payload.play_session_id)
            player.play_previous()

        self.session(event, before_send)

    def shuffle(self, event):
        def before_send(message: Message, payload: RequestPayload.PlayTrack):
            player = Player(payload.play_session_id)
            player.shuffle()

        self.session(event, before_send)

    def pause_track(self, event):
        def before_send(message: Message, payload: RequestPayload.PlayTrack):
            player = Player(payload.play_session_id)
            player.pause_track()

        self.session(event, before_send)

    def resume_track(self, event):
        def before_send(message: Message, payload: RequestPayload.PlayTrack):
            player = Player(payload.play_session_id)
            player.resume_track()

        self.session(event, before_send)

    def stop_track(self, event):
        def before_send(message: Message, payload: RequestPayload.PlayTrack):
            player = Player(payload.play_session_id)
            player.stop_track()

        self.session(event, before_send)


