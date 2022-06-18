from dataclasses import dataclass
from typing import Callable, List

from music_room.models import Playlist as PlaylistModel, Track
from music_room.serializers import PlaylistSerializer
from ws.base import BaseConsumer, TargetsEnum, Action, Message, BasePayload, BaseEvent
from music_room.services import PlaylistService


class RequestPayload:
    @dataclass
    class ModifyPlaylistTracks(BasePayload):
        track_id: int

    @dataclass
    class ModifyPlaylist(BasePayload):
        playlist_id: int
        playlist_name: str = None

    @dataclass
    class ModifyPlaylists(BasePayload):
        playlist_name: str
        type: str = PlaylistModel.Types.public


class ResponsePayload:
    @dataclass
    class Playlist(BasePayload):
        playlist: PlaylistModel
        change_message: str

    @dataclass
    class Playlists(BasePayload):
        playlists: List[PlaylistModel]


def get_playlist(f: Callable):
    def wrapper(self):
        try:
            playlist = PlaylistModel.objects.get(id=int(self.scope['url_route']['kwargs']['playlist_id']))
            return f(self, playlist)
        except PlaylistModel.DoesNotExist:
            self.close(code=401)
            return

    return wrapper


class PlaylistConsumer(BaseConsumer):
    broadcast_group = 'playlist'
    authed = True

    class Playlists(BaseEvent):
        request_payload_type = RequestPayload.ModifyPlaylists

        def action_for_initiator(self, message: Message, payload: request_payload_type):
            action = Action(
                event='playlists_changed',
                params=ResponsePayload.Playlists(
                    playlists=PlaylistSerializer(message.user.playlists.all(), many=True).data,
                ).to_data(),
                system=self.event['system']
            )
            return action

    class RenamePlaylist(Playlists, BaseEvent):
        request_payload_type = RequestPayload.ModifyPlaylist

        def before_send(self, message: Message, payload: request_payload_type):
            playlist = PlaylistService(payload.playlist_id)
            playlist.rename(payload.playlist_name)

    class AddPlaylist(Playlists, BaseEvent):
        request_payload_type = RequestPayload.ModifyPlaylists

        def before_send(self, message: Message, payload: request_payload_type):
            PlaylistModel.objects.create(name=payload.playlist_name, type=payload.type, author=message.initiator_user)

    class RemovePlaylist(Playlists, BaseEvent):
        request_payload_type = RequestPayload.ModifyPlaylist

        def before_send(self, message: Message, payload: request_payload_type):
            PlaylistModel.objects.get(id=payload.playlist_id).delete()


class PlaylistRetrieveConsumer(BaseConsumer):
    authed = True
    playlist_id = None

    # TODO Add permission for connect (only for accessed users)

    @get_playlist
    def connect(self, playlist: PlaylistModel):
        self.playlist_id = playlist.id
        self.broadcast_group = f'playlist-{self.playlist_id}'
        super(PlaylistRetrieveConsumer, self).connect()

    class Playlist(BaseEvent):
        request_payload_type = RequestPayload.ModifyPlaylistTracks
        change_message = None
        target = TargetsEnum.for_all

        def playlist(self, message: Message, payload: request_payload_type, playlist: PlaylistModel):
            action = Action(event='playlist_changed', system=self.event['system'])
            action.params = ResponsePayload.Playlist(
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

    class AddTrack(Playlist, BaseEvent):
        request_payload_type = RequestPayload.ModifyPlaylistTracks
        change_message = '{} add track {} to playlist'

        @get_playlist
        def before_send(self, message: Message, payload: request_payload_type, playlist: PlaylistModel):
            playlist = PlaylistService(playlist.id)
            playlist.add_track(payload.track_id)

    class RemoveTrack(Playlist, BaseEvent):
        request_payload_type = RequestPayload.ModifyPlaylistTracks
        change_message = '{} remove track {} from playlist'

        @get_playlist
        def before_send(self, message: Message, payload: request_payload_type, playlist: PlaylistModel):
            playlist = PlaylistService(playlist.id)
            playlist.remove_track(payload.track_id)
