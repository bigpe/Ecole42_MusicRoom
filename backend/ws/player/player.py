from typing import Union

from music_room.models import PlaySession, Playlist
from music_room.serializers import PlaySessionSerializer
from music_room.services.player import PlayerService
from ws.base import BaseConsumer, TargetsEnum, Action, Message, BaseEvent, camel_to_dot, ActionSystem, auth
from .decorators import restore_play_session, check_play_session, only_for_author, get_play_session
from .signatures import RequestPayload, ResponsePayload, CustomTargetEnum


def for_accessed(message: Union[Message, RequestPayload.ModifyTrack]):
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

    @auth
    @restore_play_session
    def connect(self, play_session: PlaySession):
        super(PlayerConsumer, self).connect()
        self.send_json(ResponsePayload.PlaySession(
            play_session=PlaySessionSerializer(play_session).data if play_session else None
        ).to_data())

    class CreateSession(BaseEvent):
        """Create play session"""
        request_payload_type = RequestPayload.CreateSession
        response_payload_type = ResponsePayload.PlaySession
        target = TargetsEnum.only_for_initiator

        def action_for_initiator(self, message: Message, payload: request_payload_type):
            play_session = PlaySession.objects.create(playlist_id=payload.playlist_id, author=message.initiator_user)
            if payload.shuffle:
                play_session = PlayerService(play_session)
                play_session.shuffle()
                play_session = play_session.play_session
            return Action(
                event='session_created',
                payload=ResponsePayload.PlaySession(play_session=PlaySessionSerializer(play_session).data).to_data(),
                system=self.event['system']
            )

    class Session(BaseEvent):
        request_payload_type = RequestPayload.ModifyTrack
        target = CustomTargetEnum.for_accessed

        @check_play_session
        def action_for_target(self, message: Message, payload: request_payload_type):
            action = Action(event='session_changed', system=self.event['system'])
            action.payload = ResponsePayload.PlaySession(
                play_session=PlaySessionSerializer(
                    PlayerService(payload.play_session_id).play_session).data).to_data(),
            return action

        @check_play_session
        def action_for_initiator(self, message: Message, payload: request_payload_type):
            action = Action(event='session_changed', system=self.event['system'])
            action.payload = ResponsePayload.PlaySession(
                play_session=PlaySessionSerializer(
                    PlayerService(payload.play_session_id).play_session).data).to_data(),
            return action

    class PlayTrack(Session, BaseEvent):
        """Play track by id, or current track if id not provided"""
        request_payload_type = RequestPayload.ModifyTrack
        response_payload_type_initiator = ResponsePayload.PlaySession
        response_payload_type_target = ResponsePayload.PlaySession

        @get_play_session
        @only_for_author
        def before_send(self, message: Message, payload: request_payload_type, play_session: PlayerService):
            play_session.play_track(payload.track_id if payload.track_id else play_session.current_track)

    class PlayNextTrack(Session, BaseEvent):
        """Play next track for current play session"""
        request_payload_type = RequestPayload.ModifyTrack
        response_payload_type_initiator = ResponsePayload.PlaySession
        response_payload_type_target = ResponsePayload.PlaySession

        @get_play_session
        @only_for_author
        def before_send(self, message: Message, payload: request_payload_type, play_session: PlayerService):
            play_session.play_next()

    class PlayPreviousTrack(Session, BaseEvent):
        """Play previous track for current play session"""
        request_payload_type = RequestPayload.ModifyTrack
        response_payload_type_initiator = ResponsePayload.PlaySession
        response_payload_type_target = ResponsePayload.PlaySession

        @get_play_session
        @only_for_author
        def before_send(self, message: Message, payload: request_payload_type, play_session: PlayerService):
            play_session.play_previous()

    class Shuffle(Session, BaseEvent):
        """Shuffle tracks for current play session"""
        request_payload_type = RequestPayload.ModifyTrack
        response_payload_type_initiator = ResponsePayload.PlaySession
        response_payload_type_target = ResponsePayload.PlaySession

        @get_play_session
        @only_for_author
        def before_send(self, message: Message, payload: request_payload_type, play_session: PlayerService):
            play_session.shuffle()

    class PauseTrack(Session, BaseEvent):
        """Pause current played track for current play session"""
        request_payload_type = RequestPayload.ModifyTrack
        response_payload_type_initiator = ResponsePayload.PlaySession
        response_payload_type_target = ResponsePayload.PlaySession

        @get_play_session
        @only_for_author
        def before_send(self, message: Message, payload: request_payload_type, play_session: PlayerService):
            play_session.pause_track()

    class ResumeTrack(Session, BaseEvent):
        """Pause current paused track for current play session"""
        request_payload_type = RequestPayload.ModifyTrack
        response_payload_type_initiator = ResponsePayload.PlaySession
        response_payload_type_target = ResponsePayload.PlaySession

        @get_play_session
        @only_for_author
        def before_send(self, message: Message, payload: request_payload_type, play_session: PlayerService):
            play_session.resume_track()

    class StopTrack(Session, BaseEvent):
        """Pause current track for current play session"""
        request_payload_type = RequestPayload.ModifyTrack
        response_payload_type_initiator = ResponsePayload.PlaySession
        response_payload_type_target = ResponsePayload.PlaySession

        @get_play_session
        @only_for_author
        def before_send(self, message: Message, payload: request_payload_type, play_session: PlayerService):
            play_session.stop_track()


class EventsList:
    session_changed: PlayerConsumer.Session = 'session.changed'
    create_session: PlayerConsumer.CreateSession = camel_to_dot(PlayerConsumer.CreateSession.__name__)
    play_track: PlayerConsumer.PlayTrack = camel_to_dot(PlayerConsumer.PlayTrack.__name__)
    play_next_track: PlayerConsumer.PlayNextTrack = camel_to_dot(PlayerConsumer.PlayNextTrack.__name__)
    play_previous_track: PlayerConsumer.PlayPreviousTrack = camel_to_dot(PlayerConsumer.PlayPreviousTrack.__name__)
    shuffle: PlayerConsumer.Shuffle = camel_to_dot(PlayerConsumer.Shuffle.__name__)
    pause_track: PlayerConsumer.PauseTrack = camel_to_dot(PlayerConsumer.PauseTrack.__name__)
    resume_track: PlayerConsumer.ResumeTrack = camel_to_dot(PlayerConsumer.ResumeTrack.__name__)
    stop_track: PlayerConsumer.StopTrack = camel_to_dot(PlayerConsumer.StopTrack.__name__)


class Examples:
    session_changed_response = Action(
        event=str(EventsList.session_changed),
        payload=ResponsePayload.PlaySession(play_session=PlaySessionSerializer(None).data).to_data(),
        system=ActionSystem()
    ).to_data(pop_system=True, to_json=True)

    create_session_request = Action(
        event=str(EventsList.create_session),
        payload=RequestPayload.CreateSession(playlist_id=1, shuffle=True).to_data(),
        system=ActionSystem()
    ).to_data(pop_system=True, to_json=True)

    play_track_request = Action(
        event=str(EventsList.play_track),
        payload=RequestPayload.ModifyTrack(play_session_id=1, track_id=1).to_data(),
        system=ActionSystem()
    ).to_data(pop_system=True, to_json=True)

    play_next_track_request = Action(
        event=str(EventsList.play_next_track),
        payload=RequestPayload.ModifyTrack(play_session_id=1).to_data(),
        system=ActionSystem()
    ).to_data(pop_system=True, to_json=True)

    play_previous_track_request = Action(
        event=str(EventsList.play_previous_track),
        payload=RequestPayload.ModifyTrack(play_session_id=1).to_data(),
        system=ActionSystem()
    ).to_data(pop_system=True, to_json=True)

    shuffle_request = Action(
        event=str(EventsList.shuffle),
        payload=RequestPayload.ModifyTrack(play_session_id=1).to_data(),
        system=ActionSystem()
    ).to_data(pop_system=True, to_json=True)

    pause_track_request = Action(
        event=str(EventsList.pause_track),
        payload=RequestPayload.ModifyTrack(play_session_id=1).to_data(),
        system=ActionSystem()
    ).to_data(pop_system=True, to_json=True)

    resume_track_request = Action(
        event=str(EventsList.resume_track),
        payload=RequestPayload.ModifyTrack(play_session_id=1).to_data(),
        system=ActionSystem()
    ).to_data(pop_system=True, to_json=True)

    stop_track_request = Action(
        event=str(EventsList.stop_track),
        payload=RequestPayload.ModifyTrack(play_session_id=1).to_data(),
        system=ActionSystem()
    ).to_data(pop_system=True, to_json=True)


