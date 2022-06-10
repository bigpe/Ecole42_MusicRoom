from dataclasses import dataclass
from typing import Callable

from music_room.models import PlaySession
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


class PlayerConsumer(BaseConsumer):
    broadcast_group = 'player'
    authed = True
    custom_target_resolver = {
        CustomTargetEnum.for_accessed:
            lambda message: message.user in PlaySession.objects.get(
                id=message.play_session_id).playlist.access_users.values_list('id', flat=True)
    }

    def _play_track(self, event, before_send: Callable = None):
        request_payload_type = RequestPayload.PlayTrack

        def action_for_target(message: Message, payload: request_payload_type):
            return Action(
                event='play_track',
                system=event['system'],
                params=list(Player(payload.play_session_id).play_session.track_queue.all().values_list('id', flat=True))
            )

        def action_for_initiator(message: Message, payload: request_payload_type):
            return Action(
                event='play_track',
                system=event['system'],
                params=PlaySessionSerializer(Player(payload.play_session_id).play_session).data
            )

        self.send_broadcast(
            event,
            action_for_target=action_for_target,
            action_for_initiator=action_for_initiator,
            before_send=before_send,
            target=CustomTargetEnum.for_all
        )

    def play_track(self, event):
        def before_send(message: Message, payload: RequestPayload.PlayTrack):
            player = Player(payload.play_session_id)
            player.play_track(payload.track_id)

        self._play_track(event, before_send)

    def play_next_track(self, event):
        def before_send(message: Message, payload: RequestPayload.PlayTrack):
            player = Player(payload.play_session_id)
            player.play_next()

        self._play_track(event, before_send)

    def play_previous_track(self, event):
        def before_send(message: Message, payload: RequestPayload.PlayTrack):
            player = Player(payload.play_session_id)
            player.play_previous()

        self._play_track(event, before_send)
