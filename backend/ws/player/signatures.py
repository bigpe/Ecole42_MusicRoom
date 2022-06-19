from dataclasses import dataclass
from typing import Optional, Union

from music_room.models import PlayerSession
from ws.base import BasePayload, TargetsEnum


class RequestPayload:
    @dataclass
    class ModifyTrack(BasePayload):
        player_session_id: int  #: Already started player session id
        track_id: Optional[int] = None  #: Optional, track id for any actions with it

    @dataclass
    class CreateSession(BasePayload):
        playlist_id: int  #: Already created playlist id
        shuffle: bool = False  #: If you need create session with shuffle tracks in playlist

    @dataclass
    class SyncTrack(BasePayload):
        progress: float  #: Track time progress from duration


class RequestPayloadWrap:
    @dataclass
    class CreateSession(BasePayload):
        create_session: Union[RequestPayload.CreateSession, dict]  #: Create session signature mock for swift

    @dataclass
    class PlayTrack(BasePayload):
        play_track: Union[RequestPayload.ModifyTrack, dict]  #: Play track signature mock for swift

    @dataclass
    class PlayNextTrack(BasePayload):
        play_next_track: Union[RequestPayload.ModifyTrack, dict]  #: Play next track signature mock for swift

    @dataclass
    class PlayPreviousTrack(BasePayload):
        play_previous_track: Union[RequestPayload.ModifyTrack, dict]  #: Play previous track signature mock for swift

    @dataclass
    class Shuffle(BasePayload):
        shuffle: Union[RequestPayload.ModifyTrack, dict]  #: Shuffle tracks signature mock for swift

    @dataclass
    class PauseTrack(BasePayload):
        pause_track: Union[RequestPayload.ModifyTrack, dict]  #: Pause track signature mock for swift

    @dataclass
    class ResumeTrack(BasePayload):
        resume_track: Union[RequestPayload.ModifyTrack, dict]  #: Resume track signature mock for swift

    @dataclass
    class StopTrack(BasePayload):
        stop_track: Union[RequestPayload.ModifyTrack, dict]  #: Stop track signature mock for swift

    @dataclass
    class SyncTrack(BasePayload):
        sync_track: Union[RequestPayload.SyncTrack, dict]  #: Sync track signature mock for swift


class ResponsePayload:
    @dataclass
    class PlayTrack(BasePayload):
        track_id: int  #: Track id

    @dataclass
    class PlayerSession(BasePayload):
        player_session: PlayerSession  #: player session object


class CustomTargetEnum(TargetsEnum):
    """Who must receive this event"""
    for_accessed = 'for_accessed'  #: Accessed user by privacy policy (invite by creator and etc.)
