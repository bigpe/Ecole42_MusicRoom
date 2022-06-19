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
        playlist_name: str = None  #: PlaylistChanged name if you want to change old name

    @dataclass
    class ModifyPlaylists(BasePayload):
        """Modify playlists"""
        playlist_name: str  #: Playlist name for create new one
        type: Union[str, Playlist.Types] = Playlist.Types.public  #: Playlist type


class RequestPayloadWrap:
    @dataclass
    class RenamePlaylist(BasePayload):
        rename_playlist: Union[RequestPayload.ModifyPlaylist, dict]  #: Rename playlist signature mock for swift

    @dataclass
    class RemovePlaylist(BasePayload):
        remove_playlist: Union[RequestPayload.ModifyPlaylist, dict]  #: Remove playlist signature mock for swift

    @dataclass
    class AddPlaylist(BasePayload):
        add_playlist: Union[RequestPayload.ModifyPlaylists, dict]  #: Add playlist signature mock for swift

    @dataclass
    class AddTrack(BasePayload):
        add_track: Union[RequestPayload.ModifyPlaylistTracks, dict]  #: Add track to playlist signature mock for swift

    @dataclass
    class RemoveTrack(BasePayload):
        #: Remove track from playlist signature mock for swift
        remove_track: Union[RequestPayload.ModifyPlaylistTracks, dict]


class ResponsePayload:
    @dataclass
    class PlaylistChanged(BasePayload):
        playlist: Playlist  #: Playlist object
        change_message: str  #: Message provided for change action

    @dataclass
    class PlaylistsChanged(BasePayload):
        playlists: List[Playlist]  #: Playlists objects
