from dataclasses import dataclass
from typing import Callable, List

from music_room.models import Playlist, Track
from music_room.serializers import PlaylistSerializer
from ws.base import BaseConsumer, TargetsEnum, Action, Message, BasePayload
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
        type: str = Playlist.Types.public


class ResponsePayload:
    @dataclass
    class Playlist(BasePayload):
        playlist: Playlist
        change_message: str

    @dataclass
    class Playlists(BasePayload):
        playlists: List[Playlist]


def check_playlist(f: Callable):
    def wrapper(self):
        try:
            playlist = Playlist.objects.get(id=int(self.scope['url_route']['kwargs']['playlist_id']))
            return f(self, playlist)
        except Playlist.DoesNotExist:
            self.close(code=401)
            return

    return wrapper


class PlaylistConsumer(BaseConsumer):
    broadcast_group = 'playlist'
    authed = True

    def playlists(self, event, before_send: Callable = None, payload_type=None):
        request_payload_type = RequestPayload.ModifyPlaylists
        action = Action(event='playlists_changed', system=event['system'])

        def action_for_initiator(message: Message, payload: request_payload_type):
            action.params = ResponsePayload.Playlists(
                playlists=PlaylistSerializer(message.user.playlists.all(), many=True).data,
            ).to_data()
            return action

        self.send_broadcast(
            event,
            action_for_initiator=action_for_initiator,
            before_send=before_send,
            target=TargetsEnum.only_for_initiator,
            payload_type=payload_type
        )

    def rename_playlist(self, event):
        def before_send(message: Message, payload: RequestPayload.ModifyPlaylist):
            playlist = PlaylistService(payload.playlist_id)
            playlist.rename(payload.playlist_name)

        self.playlists(event, before_send)

    def add_playlist(self, event):
        def before_send(message: Message, payload: RequestPayload.ModifyPlaylists):
            Playlist.objects.create(name=payload.playlist_name, type=payload.type, author=message.initiator_user)

        self.playlists(event, before_send, payload_type=RequestPayload.ModifyPlaylists)

    def remove_playlist(self, event):
        def before_send(message: Message, payload: RequestPayload.ModifyPlaylist):
            Playlist.objects.get(id=payload.playlist_id).delete()

        self.playlists(event, before_send)


class PlaylistRetrieveConsumer(BaseConsumer):
    authed = True
    playlist_id = None

    # TODO Add permission for connect (only for accessed users)

    @check_playlist
    def connect(self, playlist: Playlist):
        self.playlist_id = playlist.id
        self.broadcast_group = f'playlist-{self.playlist_id}'
        super(PlaylistRetrieveConsumer, self).connect()

    def playlist(self, event, before_send: Callable = None, change_message=None):
        request_payload_type = RequestPayload.ModifyPlaylistTracks
        action = Action(event='playlist_changed', system=event['system'])

        def action_for_target(message: Message, payload: request_payload_type):
            action.params = ResponsePayload.Playlist(
                playlist=PlaylistSerializer(PlaylistService(self.playlist_id).playlist).data,
                change_message=change_message.format(
                    message.initiator_user.username,
                    Track.objects.get(id=payload.track_id).name
                )
            ).to_data()
            return action

        def action_for_initiator(message: Message, payload: request_payload_type):
            action.params = ResponsePayload.Playlist(
                playlist=PlaylistSerializer(PlaylistService(self.playlist_id).playlist).data,
                change_message=change_message.format(
                    message.initiator_user.username,
                    Track.objects.get(id=payload.track_id).name
                )
            ).to_data()
            return action

        self.send_broadcast(
            event,
            action_for_target=action_for_target,
            action_for_initiator=action_for_initiator,
            before_send=before_send,
            target=TargetsEnum.for_all
        )

    def add_track(self, event):
        def before_send(message: Message, payload: RequestPayload.ModifyPlaylistTracks):
            playlist = PlaylistService(self.playlist_id)
            playlist.add_track(payload.track_id)

        self.playlist(event, before_send, change_message='{} add track {} to playlist')

    def remove_track(self, event):
        def before_send(message: Message, payload: RequestPayload.ModifyPlaylistTracks):
            playlist = PlaylistService(self.playlist_id)
            playlist.remove_track(payload.track_id)

        self.playlist(event, before_send, change_message='{} remove track {} from playlist')