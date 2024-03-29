from dataclasses import dataclass
from typing import Union

from music_room.models import Playlist, Event, EventAccess
from ws.base import BasePayload


class RequestPayload:
    @dataclass
    class AddEventTrack(BasePayload):
        """Add track to event"""
        player_session_id: int  #: Player session id
        track_id: int  #: Track id

    @dataclass
    class RemoveEventTrack(BasePayload):
        """Remove track from event"""
        player_session_id: int  #: Player session id
        session_track_id: int  #: Session track if

    @dataclass
    class ModifyEvent(BasePayload):
        """Modify event"""
        event_name: str = None  #: Event name if you want to change old name
        event_access_type: Event.AccessTypes = None  #: Event access type

    @dataclass
    class ModifyEventAccess(BasePayload):
        """Modify playlist access"""
        user_id: int  #: User id to grant/remove access to event

    @dataclass
    class ModifyUserAccessMode(BasePayload):
        """Modify playlist access"""
        user_id: int  #: User id to change role
        access_mode: EventAccess.AccessMode  #: New one access mode (role)


class RequestPayloadWrap:
    @dataclass
    class AddTrack(BasePayload):
        #: Add track to event session signature mock for swift
        add_track: Union[RequestPayload.AddEventTrack, dict]

    @dataclass
    class RemoveTrack(BasePayload):
        #: Remove track from event session signature mock for swift
        remove_track: Union[RequestPayload.RemoveEventTrack, dict]

    @dataclass
    class InviteToEvent(BasePayload):
        #: Invite someone to access this event mock for swift
        invite_to_event: Union[RequestPayload.ModifyEventAccess, dict]

    @dataclass
    class RevokeFromEvent(BasePayload):
        #: Revoke user's access from this event mock for swift
        revoke_from_event: Union[RequestPayload.ModifyEventAccess, dict]

    @dataclass
    class ChangeEvent(BasePayload):
        #: Change event signature mock for swift
        change_event: Union[RequestPayload.ModifyEvent, dict]

    @dataclass
    class ChangeUserAccessMode(BasePayload):
        #: Change user's access mode mock for swift
        change_user_access_mode: Union[RequestPayload.ModifyUserAccessMode, dict]


class ResponsePayload:
    @dataclass
    class PlaylistChanged(BasePayload):
        playlist: Playlist  #: Playlist object
        change_message: str  #: Message provided for change action

    @dataclass
    class EventChanged(BasePayload):
        event: Event  #: Event object
        change_message: str  #: Message provided for change action
