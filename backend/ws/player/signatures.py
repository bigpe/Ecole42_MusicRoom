from dataclasses import dataclass
from typing import Optional

from music_room.models import PlaySession
from ws.base import BasePayload, TargetsEnum


class RequestPayload:
    @dataclass
    class ModifyTrack(BasePayload):
        play_session_id: int  #: Already started play session id
        track_id: Optional[int] = None  #: Optional, track id for any actions with it

    @dataclass
    class CreateSession(BasePayload):
        playlist_id: int  #: Already created playlist id
        shuffle: bool = False  #: If you need create session with shuffle tracks in playlist

    @dataclass
    class RemoveSession(BasePayload):
        play_session_id: int  #: Already started play session id


class ResponsePayload:
    @dataclass
    class PlayTrack(BasePayload):
        track_id: int  #: Track id

    @dataclass
    class PlaySession(BasePayload):
        play_session: PlaySession  #: Play session object


class CustomTargetEnum(TargetsEnum):
    """Who must receive this event"""
    for_accessed = 'for_accessed'  #: Accessed user by privacy policy (invite by creator and etc.)
