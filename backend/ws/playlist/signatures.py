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
        playlist_name: str  #: PlaylistChanged name for create new one
        type: Union[str, Playlist.Types] = Playlist.Types.public  #: PlaylistChanged type


class ResponsePayload:
    @dataclass
    class Playlist(BasePayload):
        playlist: Playlist  #: PlaylistChanged object
        change_message: str  #: Message provided for change action

    @dataclass
    class Playlists(BasePayload):
        playlists: List[Playlist]  #: PlaylistsChanged objects
