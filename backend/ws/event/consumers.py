from music_room.serializers import PlaylistSerializer, EventListSerializer, EventSerializer
from music_room.services import PlaylistService
from music_room.services.event import EventService
from ws.utils import BaseConsumerRef as BaseConsumer
from .decorators import get_event_from_path, only_for_accessed, get_playlist, get_event, only_for_staff, \
    only_for_administrator
from .signatures import RequestPayload, ResponsePayload, RequestPayloadWrap
from ws.base import TargetsEnum, Message, ActionSystem, Action, camel_to_dot
from ..base import BaseEvent
from music_room.models import Playlist as PlaylistModel, Track, Event, EventAccess


class EventRetrieveConsumer(BaseConsumer):
    authed = True
    event_id = None

    request_type_resolver = {
        'change_event': RequestPayloadWrap.ChangeEvent,
        'change_user_access_mode': RequestPayloadWrap.ChangeUserAccessMode,
        'add_track': RequestPayloadWrap.AddTrack,
        'remove_track': RequestPayloadWrap.RemoveTrack,
        'invite_to_event': RequestPayloadWrap.InviteToEvent,
        'revoke_from_event': RequestPayloadWrap.RevokeFromEvent,
    }

    @get_event_from_path
    @only_for_accessed
    def after_connect(self, event):
        self.event_id = event.id
        self.broadcast_group = f'event-{event.id}'
        self.join_group(self.broadcast_group)

    class PlaylistChanged(BaseEvent):
        request_payload_type = RequestPayload.ModifyPlaylistTracks
        change_message = None
        target = TargetsEnum.for_all
        hidden = True

        def playlist(self, message: Message, payload: request_payload_type, playlist: PlaylistModel):
            action = Action(event=str(EventsList.playlist_changed), system=self.event['system'])
            action.payload = ResponsePayload.PlaylistChanged(
                playlist=PlaylistSerializer(PlaylistService(playlist.id).playlist).data,
                change_message=self.change_message.format(
                    message.initiator_user.username,
                    Track.objects.get(id=payload.track_id).name
                )
            ).to_data()
            return action

        @get_playlist
        def action_for_target(self, message: Message, payload: request_payload_type, playlist: PlaylistModel):
            return self.playlist(message, payload, playlist)

        @get_playlist
        def action_for_initiator(self, message: Message, payload: request_payload_type, playlist: PlaylistModel):
            return self.playlist(message, payload, playlist)

    class EventChanged(BaseEvent):
        request_payload_type = RequestPayload.ModifyEvent
        target = TargetsEnum.for_all
        hidden = True

        @get_event
        def action_for_target(self, message: Message, payload: request_payload_type, event: Event):
            return Action(
                event=str(EventsList.playlist_changed),
                payload=ResponsePayload.EventChanged(
                    event=EventSerializer(event).data,
                    change_message='Someone change event data'
                ),
                system=self.event['system']
            )

    class ChangeEvent(EventChanged, BaseEvent):
        """Change already existed event"""
        request_payload_type = RequestPayload.ModifyEvent
        response_payload_type_initiator = ResponsePayload.EventChanged
        hidden = False

        @get_event
        @only_for_administrator
        def before_send(self, message: Message, payload: request_payload_type, event: Event):
            event = EventService(event.id)
            event.change(
                name=payload.event_name,
                access_type=payload.event_access_type
            )

    class AddTrack(PlaylistChanged, BaseEvent):
        """Add track to already existed playlist"""
        request_payload_type = RequestPayload.ModifyPlaylistTracks
        change_message = '{} add track {} to playlist'
        response_payload_type_target = ResponsePayload.PlaylistChanged
        response_payload_type_initiator = ResponsePayload.PlaylistChanged
        hidden = False

        @get_playlist
        @get_event
        @only_for_staff
        def before_send(self, message: Message, payload: request_payload_type, playlist: PlaylistModel, event: Event):
            playlist = PlaylistService(playlist.id)
            playlist.add_track(payload.track_id)

    class RemoveTrack(PlaylistChanged, BaseEvent):
        """Remove track from already existed playlist"""
        request_payload_type = RequestPayload.ModifyPlaylistTracks
        change_message = '{} remove track {} from playlist'
        response_payload_type_target = ResponsePayload.PlaylistChanged
        response_payload_type_initiator = ResponsePayload.PlaylistChanged
        hidden = False

        @get_playlist
        @get_event
        @only_for_staff
        def before_send(self, message: Message, payload: request_payload_type, playlist: PlaylistModel, event: Event):
            playlist = PlaylistService(playlist.id)
            playlist.remove_track(payload.track_id)

    class InviteToEvent(EventChanged, BaseEvent):
        """Invite someone to access this event"""
        request_payload_type = RequestPayload.ModifyEventAccess
        hidden = False

        @get_event
        @only_for_staff
        def before_send(self, message: Message, payload: request_payload_type, event: Event):
            event = EventService(event.id)
            event.invite_user(payload.user_id)

    class RevokeFromEvent(EventChanged, BaseEvent):
        """Revoke user's access from this event"""
        request_payload_type = RequestPayload.ModifyEventAccess
        hidden = False

        @get_event
        @only_for_staff
        def before_send(self, message: Message, payload: request_payload_type, event: Event):
            event = EventService(event.id)
            event.revoke_user(payload.user_id)

    class ChangeUserAccessMode(BaseEvent):
        """Change user's access mode (role)"""
        request_payload_type = RequestPayload.ModifyUserAccessMode
        hidden = False

        @get_event
        @only_for_administrator
        def before_send(self, message: Message, payload: request_payload_type, event: Event):
            event = EventService(event.id)
            event.change_user_access_mode(user_id=payload.user_id, access_mode=payload.access_mode)


class EventsList:
    change_event: EventRetrieveConsumer.ChangeEvent = camel_to_dot(
        EventRetrieveConsumer.ChangeEvent.__name__)
    playlist_changed: EventRetrieveConsumer.PlaylistChanged = camel_to_dot(
        EventRetrieveConsumer.PlaylistChanged.__name__)
    event_changed: EventRetrieveConsumer.EventChanged = camel_to_dot(
        EventRetrieveConsumer.EventChanged.__name__)
    add_track: EventRetrieveConsumer.AddTrack = camel_to_dot(EventRetrieveConsumer.AddTrack.__name__)
    remove_track: EventRetrieveConsumer.RemoveTrack = camel_to_dot(EventRetrieveConsumer.RemoveTrack.__name__)
    invite_to_event: EventRetrieveConsumer.InviteToEvent = camel_to_dot(
        EventRetrieveConsumer.InviteToEvent.__name__)
    revoke_from_event: EventRetrieveConsumer.RevokeFromEvent = camel_to_dot(
        EventRetrieveConsumer.RevokeFromEvent.__name__)
    change_user_access_mode: EventRetrieveConsumer.ChangeUserAccessMode = camel_to_dot(
        EventRetrieveConsumer.ChangeUserAccessMode.__name__)


class Examples:
    event_change_event_request = Action(
        event=str(EventsList.change_event),
        payload=RequestPayload.ModifyEvent(
            event_name='Test',
            event_access_type=Event.AccessTypes.public
        ).to_data(),
        system=ActionSystem()
    ).to_data(pop_system=True, to_json=True)

    event_playlist_changed_response = Action(
        event=str(EventsList.playlist_changed),
        payload=ResponsePayload.PlaylistChanged(
            playlist=PlaylistSerializer(None).data,
            change_message='Someone add track to playlist').to_data(),
        system=ActionSystem()
    ).to_data(pop_system=True, to_json=True)

    event_changed_response = Action(
        event=str(EventsList.event_changed),
        payload=ResponsePayload.EventChanged(
            event=EventSerializer(None).data,
            change_message='Someone change name of event').to_data(),
        system=ActionSystem()
    ).to_data(pop_system=True, to_json=True)

    event_add_track_request = Action(
        event=str(EventsList.add_track),
        payload=RequestPayload.ModifyPlaylistTracks(track_id=1).to_data(),
        system=ActionSystem()
    ).to_data(pop_system=True, to_json=True)

    event_remove_track_request = Action(
        event=str(EventsList.remove_track),
        payload=RequestPayload.ModifyPlaylistTracks(track_id=1).to_data(),
        system=ActionSystem()
    ).to_data(pop_system=True, to_json=True)

    event_invite_to_event_request = Action(
        event=str(EventsList.invite_to_event),
        payload=RequestPayload.ModifyEventAccess(user_id=1).to_data(),
        system=ActionSystem()
    ).to_data(pop_system=True, to_json=True)

    event_revoke_from_event_request = Action(
        event=str(EventsList.revoke_from_event),
        payload=RequestPayload.ModifyEventAccess(user_id=1).to_data(),
        system=ActionSystem()
    ).to_data(pop_system=True, to_json=True)

    event_change_user_access_mode_request = Action(
        event=str(EventsList.change_user_access_mode),
        payload=RequestPayload.ModifyUserAccessMode(user_id=1, access_mode=EventAccess.AccessMode.moderator).to_data(),
        system=ActionSystem()
    ).to_data(pop_system=True, to_json=True)
