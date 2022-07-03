from dataclasses import dataclass
from typing import List, Union

from music_room.models import Playlist
from ws.base import BasePayload


class RequestPayload:
    @dataclass
    class ModifyPlaylistTracks(BasePayload):
        """Modify playlist tracks"""
        track_id: int  #: Track if for any actions with it (eg. remove, add)

    @dataclass
    class ModifyPlaylist(BasePayload):
        """Modify playlist"""
        playlist_id: int  #: Already created playlist id
        playlist_name: str = None  #: Playlist name if you want to change old name
        playlist_access_type: Playlist.AccessTypes = None  #: Playlist access type

    @dataclass
    class ModifyPlaylists(BasePayload):
        """Modify playlists"""
        playlist_name: str  #: Playlist name for create new one
        access_type: Union[str, Playlist.AccessTypes] = Playlist.AccessTypes.public  #: Playlist access type

    @dataclass
    class ModifyPlaylistAccess(BasePayload):
        """Modify playlist access"""
        user_id: int  #: User id to grant/remove access to playlist


class RequestPayloadWrap:
    @dataclass
    class ChangePlaylist(BasePayload):
        #: Change playlist signature mock for swift
        change_playlist: Union[RequestPayload.ModifyPlaylist, dict]

    @dataclass
    class RemovePlaylist(BasePayload):
        #: Remove playlist signature mock for swift
        remove_playlist: Union[RequestPayload.ModifyPlaylist, dict]

    @dataclass
    class AddPlaylist(BasePayload):
        #: Add playlist signature mock for swift
        add_playlist: Union[RequestPayload.ModifyPlaylists, dict]

    @dataclass
    class AddTrack(BasePayload):
        #: Add track to playlist signature mock for swift
        add_track: Union[RequestPayload.ModifyPlaylistTracks, dict]

    @dataclass
    class RemoveTrack(BasePayload):
        #: Remove track from playlist signature mock for swift
        remove_track: Union[RequestPayload.ModifyPlaylistTracks, dict]

    @dataclass
    class InviteToPlaylist(BasePayload):
        #: Invite someone to access this playlist mock for swift
        invite_to_playlist: Union[RequestPayload.ModifyPlaylistAccess, dict]

    @dataclass
    class RevokeFromPlaylist(BasePayload):
        #: Revoke user's access from this playlist mock for swift
        revoke_from_playlist: Union[RequestPayload.ModifyPlaylistAccess, dict]


class ResponsePayload:
    @dataclass
    class PlaylistChanged(BasePayload):
        playlist: Playlist  #: Playlist object
        change_message: str  #: Message provided for change action

    @dataclass
    class PlaylistsChanged(BasePayload):
        playlists: List[Playlist]  #: Playlists objects
