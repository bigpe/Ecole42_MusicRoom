from typing import Union

from music_room.models import PlayerSession, Playlist
from music_room.serializers import PlayerSessionSerializer
from music_room.services.player import PlayerService
from ws.base import TargetsEnum, Message, BaseEvent, camel_to_dot, ActionSystem
from ws.utils import ActionRef as Action, BaseConsumerRef as BaseConsumer
from .decorators import restore_player_session, check_player_session, get_player_service, get_playlist
from .signatures import RequestPayload, ResponsePayload, CustomTargetEnum, RequestPayloadWrap


def for_accessed(message: Union[Message, RequestPayload.ModifyTrack]):
    player_session = PlayerSession.objects.get(id=message.player_session_id)
    if player_session.playlist.access_type == Playlist.AccessTypes.public:
        return True
    if message.user in player_session.playlist.playlist_access_users.values_list('id', flat=True):
        return True
    return False


class PlayerConsumer(BaseConsumer):
    broadcast_group = 'player'
    authed = True
    custom_target_resolver = {CustomTargetEnum.for_accessed: for_accessed}
    multiplayer = False

    request_type_resolver = {
        'create_session': RequestPayloadWrap.CreateSession,
        'play_track': RequestPayloadWrap.PlayTrack,
        'play_next_track': RequestPayloadWrap.PlayNextTrack,
        'play_previous_track': RequestPayloadWrap.PlayPreviousTrack,
        'shuffle': RequestPayloadWrap.Shuffle,
        'pause_track': RequestPayloadWrap.PauseTrack,
        'resume_track': RequestPayloadWrap.ResumeTrack,
        'stop_track': RequestPayloadWrap.StopTrack,
    }

    @restore_player_session
    def after_connect(self, player_session: PlayerSession):
        self.Session(consumer=self)

    @restore_player_session
    def before_disconnect(self, player_session: PlayerSession):
        if player_session:
            PlayerService(player_session).freeze_session()

    class Session(BaseEvent):
        request_payload_type = None
        hidden = True

        @restore_player_session
        def action_for_initiator(self, message: Message, payload: request_payload_type, player_session: PlayerSession):
            return Action(
                event=str(EventsList.session),
                payload=ResponsePayload.PlayerSession(
                    player_session=PlayerSessionSerializer(player_session).data if player_session else None
                ).to_data(),
                system=self.event['system']
            )

    class CreateSession(BaseEvent):
        """Create player session"""
        request_payload_type = RequestPayload.CreateSession
        response_payload_type = ResponsePayload.PlayerSession
        target = TargetsEnum.only_for_initiator

        @get_playlist
        def action_for_initiator(self, message: Message, payload: request_payload_type, playlist: Playlist):
            player_session = PlayerSession.objects.create(playlist=playlist, author=message.initiator_user)
            if payload.shuffle:
                player_session = PlayerService(player_session)
                player_session.shuffle()
                player_session = player_session.player_session
            return Action(
                event=str(EventsList.session_changed),
                payload=ResponsePayload.PlayerSession(
                    player_session=PlayerSessionSerializer(player_session).data).to_data(),
                system=self.event['system']
            )

    class RemoveSession(BaseEvent):
        """Remove player session"""
        request_payload_type = None

        def before_send(self, message: Message, payload: request_payload_type):
            PlayerSession.objects.filter(author=message.initiator_user).delete()

    class SessionChanged(BaseEvent):
        request_payload_type = RequestPayload.ModifyTrack
        target = CustomTargetEnum.for_accessed
        hidden = True

        @check_player_session
        def action_for_target(self, message: Message, payload: request_payload_type):
            action = Action(
                event=str(EventsList.session_changed),
                payload=ResponsePayload.PlayerSession(
                    player_session=PlayerSessionSerializer(
                        PlayerService(payload.player_session_id).player_session).data).to_data(),
                system=self.event['system']
            )
            return action

        @check_player_session
        def action_for_initiator(self, message: Message, payload: request_payload_type):
            action = Action(
                event=str(EventsList.session_changed),
                payload=ResponsePayload.PlayerSession(
                    player_session=PlayerSessionSerializer(
                        PlayerService(payload.player_session_id).player_session).data).to_data(),
                system=self.event['system']
            )
            return action

    class PlayTrack(SessionChanged, BaseEvent):
        """Play track by id, or current track if id not provided"""
        request_payload_type = RequestPayload.ModifyTrack
        response_payload_type_initiator = ResponsePayload.PlayerSession
        response_payload_type_target = ResponsePayload.PlayerSession
        hidden = False

        @get_player_service
        def before_send(self, message: Message, payload: request_payload_type, player_service: PlayerService):
            player_service.play_track(payload.track_id if payload.track_id else player_service.current_track)

    class DelayPlayTrack(SessionChanged, BaseEvent):
        """Delay play track by id (push track to top of queue)"""
        request_payload_type = RequestPayload.DelayPlayTrack
        response_payload_type_initiator = ResponsePayload.PlayerSession
        response_payload_type_target = ResponsePayload.PlayerSession
        hidden = False

        @get_player_service
        def before_send(self, message: Message, payload: request_payload_type, player_service: PlayerService):
            player_service.delay_play_track(payload.track_id)

    class PlayNextTrack(SessionChanged, BaseEvent):
        """Play next track for current player session"""
        request_payload_type = RequestPayload.ModifyTrack
        response_payload_type_initiator = ResponsePayload.PlayerSession
        response_payload_type_target = ResponsePayload.PlayerSession
        hidden = False

        @get_player_service
        def before_send(self, message: Message, payload: request_payload_type, player_service: PlayerService):
            player_service.play_next()

    class PlayPreviousTrack(SessionChanged, BaseEvent):
        """Play previous track for current player session"""
        request_payload_type = RequestPayload.ModifyTrack
        response_payload_type_initiator = ResponsePayload.PlayerSession
        response_payload_type_target = ResponsePayload.PlayerSession
        hidden = False

        @get_player_service
        def before_send(self, message: Message, payload: request_payload_type, player_service: PlayerService):
            player_service.play_previous()

    class Shuffle(SessionChanged, BaseEvent):
        """Shuffle tracks for current player session"""
        request_payload_type = RequestPayload.ModifyTrack
        response_payload_type_initiator = ResponsePayload.PlayerSession
        response_payload_type_target = ResponsePayload.PlayerSession
        hidden = False

        @get_player_service
        def before_send(self, message: Message, payload: request_payload_type, player_service: PlayerService):
            player_service.shuffle()

    class PauseTrack(SessionChanged, BaseEvent):
        """Pause current played track for current player session"""
        request_payload_type = RequestPayload.ModifyTrack
        response_payload_type_initiator = ResponsePayload.PlayerSession
        response_payload_type_target = ResponsePayload.PlayerSession
        hidden = False

        @get_player_service
        def before_send(self, message: Message, payload: request_payload_type, player_service: PlayerService):
            player_service.pause_track()

    class ResumeTrack(SessionChanged, BaseEvent):
        """Pause current paused track for current player session"""
        request_payload_type = RequestPayload.ModifyTrack
        response_payload_type_initiator = ResponsePayload.PlayerSession
        response_payload_type_target = ResponsePayload.PlayerSession
        hidden = False

        @get_player_service
        def before_send(self, message: Message, payload: request_payload_type, player_service: PlayerService):
            player_service.resume_track()

    class StopTrack(SessionChanged, BaseEvent):
        """Pause current track for current player session"""
        request_payload_type = RequestPayload.ModifyTrack
        response_payload_type_initiator = ResponsePayload.PlayerSession
        response_payload_type_target = ResponsePayload.PlayerSession
        hidden = False

        @get_player_service
        def before_send(self, message: Message, payload: request_payload_type, player_service: PlayerService):
            player_service.stop_track()

    class SyncTrack(BaseEvent):
        """Sync current track progress from duration for current player session"""
        request_payload_type = RequestPayload.SyncTrack

        @get_player_service
        def before_send(self, message: Message, payload: request_payload_type, player_service: PlayerService):
            player_service.sync_track(payload.progress)

    class VoteTrack(SessionChanged, BaseEvent):
        """Vote to next track"""
        request_payload_type = RequestPayload.VoteTrack
        response_payload_type_initiator = ResponsePayload.PlayerSession
        response_payload_type_target = ResponsePayload.PlayerSession
        hidden = False

        @get_player_service
        def before_send(self, message: Message, payload: request_payload_type, player_service: PlayerService):
            player_service.vote(track=payload.track_id, user=message.initiator_user)


class EventsList:
    session: PlayerConsumer.Session = camel_to_dot(PlayerConsumer.Session.__name__)
    session_changed: PlayerConsumer.SessionChanged = camel_to_dot(PlayerConsumer.SessionChanged.__name__)
    create_session: PlayerConsumer.CreateSession = camel_to_dot(PlayerConsumer.CreateSession.__name__)
    remove_session: PlayerConsumer.RemoveSession = camel_to_dot(PlayerConsumer.RemoveSession.__name__)
    play_track: PlayerConsumer.PlayTrack = camel_to_dot(PlayerConsumer.PlayTrack.__name__)
    delay_play_track: PlayerConsumer.DelayPlayTrack = camel_to_dot(PlayerConsumer.DelayPlayTrack.__name__)
    play_next_track: PlayerConsumer.PlayNextTrack = camel_to_dot(PlayerConsumer.PlayNextTrack.__name__)
    play_previous_track: PlayerConsumer.PlayPreviousTrack = camel_to_dot(PlayerConsumer.PlayPreviousTrack.__name__)
    shuffle: PlayerConsumer.Shuffle = camel_to_dot(PlayerConsumer.Shuffle.__name__)
    pause_track: PlayerConsumer.PauseTrack = camel_to_dot(PlayerConsumer.PauseTrack.__name__)
    resume_track: PlayerConsumer.ResumeTrack = camel_to_dot(PlayerConsumer.ResumeTrack.__name__)
    stop_track: PlayerConsumer.StopTrack = camel_to_dot(PlayerConsumer.StopTrack.__name__)
    sync_track: PlayerConsumer.SyncTrack = camel_to_dot(PlayerConsumer.SyncTrack.__name__)
    vote_track: PlayerConsumer.VoteTrack = camel_to_dot(PlayerConsumer.VoteTrack.__name__)


class Examples:
    session_response = Action(
        event=str(EventsList.session),
        payload=ResponsePayload.PlayerSession(player_session=PlayerSessionSerializer(None).data).to_data(),
        system=ActionSystem()
    ).to_data(pop_system=True, to_json=True)

    session_changed_response = Action(
        event=str(EventsList.session_changed),
        payload=ResponsePayload.PlayerSession(player_session=PlayerSessionSerializer(None).data).to_data(),
        system=ActionSystem()
    ).to_data(pop_system=True, to_json=True)

    create_session_request = Action(
        event=str(EventsList.create_session),
        payload=RequestPayload.CreateSession(playlist_id=1, shuffle=True).to_data(),
        system=ActionSystem()
    ).to_data(pop_system=True, to_json=True)

    remove_session_request = Action(
        event=str(EventsList.remove_session),
        payload=None,
        system=ActionSystem()
    ).to_data(pop_system=True, to_json=True)

    play_track_request = Action(
        event=str(EventsList.play_track),
        payload=RequestPayload.ModifyTrack(player_session_id=1, track_id=1).to_data(),
        system=ActionSystem()
    ).to_data(pop_system=True, to_json=True)

    delay_play_track_request = Action(
        event=str(EventsList.delay_play_track),
        payload=RequestPayload.DelayPlayTrack(player_session_id=1, track_id=1).to_data(),
        system=ActionSystem()
    ).to_data(pop_system=True, to_json=True)

    play_next_track_request = Action(
        event=str(EventsList.play_next_track),
        payload=RequestPayload.ModifyTrack(player_session_id=1).to_data(),
        system=ActionSystem()
    ).to_data(pop_system=True, to_json=True)

    play_previous_track_request = Action(
        event=str(EventsList.play_previous_track),
        payload=RequestPayload.ModifyTrack(player_session_id=1).to_data(),
        system=ActionSystem()
    ).to_data(pop_system=True, to_json=True)

    shuffle_request = Action(
        event=str(EventsList.shuffle),
        payload=RequestPayload.ModifyTrack(player_session_id=1).to_data(),
        system=ActionSystem()
    ).to_data(pop_system=True, to_json=True)

    pause_track_request = Action(
        event=str(EventsList.pause_track),
        payload=RequestPayload.ModifyTrack(player_session_id=1).to_data(),
        system=ActionSystem()
    ).to_data(pop_system=True, to_json=True)

    resume_track_request = Action(
        event=str(EventsList.resume_track),
        payload=RequestPayload.ModifyTrack(player_session_id=1).to_data(),
        system=ActionSystem()
    ).to_data(pop_system=True, to_json=True)

    stop_track_request = Action(
        event=str(EventsList.stop_track),
        payload=RequestPayload.ModifyTrack(player_session_id=1).to_data(),
        system=ActionSystem()
    ).to_data(pop_system=True, to_json=True)

    sync_track_request = Action(
        event=str(EventsList.sync_track),
        payload=RequestPayload.SyncTrack(progress=10.5, player_session_id=1).to_data(),
        system=ActionSystem()
    ).to_data(pop_system=True, to_json=True)

    vote_track_request = Action(
        event=str(EventsList.vote_track),
        payload=RequestPayload.VoteTrack(player_session_id=1, track_id=1).to_data(),
        system=ActionSystem()
    ).to_data(pop_system=True, to_json=True)
