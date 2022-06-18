from music_room.models import Playlist as PlaylistModel, Track, Playlist
from music_room.serializers import PlaylistSerializer
from ws.base import BaseConsumer, TargetsEnum, Action, Message, BaseEvent, ActionSystem
from music_room.services import PlaylistService
from .decorators import get_playlist
from .signatures import RequestPayload, ResponsePayload

from ws.base.utils import camel_to_dot


class PlaylistsConsumer(BaseConsumer):
    broadcast_group = 'playlist'
    authed = True

    class PlaylistsChanged(BaseEvent):
        request_payload_type = RequestPayload.ModifyPlaylists

        def action_for_initiator(self, message: Message, payload: request_payload_type):
            action = Action(
                event=str(EventsList.playlists_changed),
                payload=ResponsePayload.Playlists(
                    playlists=PlaylistSerializer(message.user.playlists.all(), many=True).data,
                ).to_data(),
                system=self.event['system']
            )
            return action

    class RenamePlaylist(PlaylistsChanged, BaseEvent):
        """Rename already existed playlist"""
        request_payload_type = RequestPayload.ModifyPlaylist
        response_payload_type_initiator = ResponsePayload.Playlists

        def before_send(self, message: Message, payload: request_payload_type):
            playlist = PlaylistService(payload.playlist_id)
            playlist.rename(payload.playlist_name)

    class AddPlaylist(PlaylistsChanged, BaseEvent):
        """Add new playlist"""
        request_payload_type = RequestPayload.ModifyPlaylists
        response_payload_type_initiator = ResponsePayload.Playlists

        def before_send(self, message: Message, payload: request_payload_type):
            PlaylistModel.objects.create(name=payload.playlist_name, type=payload.type, author=message.initiator_user)

    class RemovePlaylist(PlaylistsChanged, BaseEvent):
        """Remove already created playlist"""
        request_payload_type = RequestPayload.ModifyPlaylist
        response_payload_type_initiator = ResponsePayload.Playlists

        def before_send(self, message: Message, payload: request_payload_type):
            PlaylistModel.objects.get(id=payload.playlist_id).delete()


class PlaylistRetrieveConsumer(BaseConsumer):
    authed = True

    # TODO Add permission for connect (only for accessed users)

    @get_playlist
    def after_connect(self, playlist: PlaylistModel):
        self.broadcast_group = f'playlist-{playlist.id}'
        self.join_group(self.broadcast_group)

    class PlaylistChanged(BaseEvent):
        request_payload_type = RequestPayload.ModifyPlaylistTracks
        change_message = None
        target = TargetsEnum.for_all

        def playlist(self, message: Message, payload: request_payload_type, playlist: PlaylistModel):
            action = Action(event=str(EventsList.playlist_changed), system=self.event['system'])
            action.payload = ResponsePayload.Playlist(
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

    class AddTrack(PlaylistChanged, BaseEvent):
        """Add track to already existed playlist"""
        request_payload_type = RequestPayload.ModifyPlaylistTracks
        change_message = '{} add track {} to playlist'
        response_payload_type_target = ResponsePayload.Playlist
        response_payload_type_initiator = ResponsePayload.Playlist

        @get_playlist
        def before_send(self, message: Message, payload: request_payload_type, playlist: PlaylistModel):
            playlist = PlaylistService(playlist.id)
            playlist.add_track(payload.track_id)

    class RemoveTrack(PlaylistChanged, BaseEvent):
        """Remove track from already existed playlist"""
        request_payload_type = RequestPayload.ModifyPlaylistTracks
        change_message = '{} remove track {} from playlist'
        response_payload_type_target = ResponsePayload.Playlist
        response_payload_type_initiator = ResponsePayload.Playlist

        @get_playlist
        def before_send(self, message: Message, payload: request_payload_type, playlist: PlaylistModel):
            playlist = PlaylistService(playlist.id)
            playlist.remove_track(payload.track_id)


class EventsList:
    playlist_changed: PlaylistRetrieveConsumer.PlaylistChanged = camel_to_dot(
        PlaylistRetrieveConsumer.PlaylistChanged.__name__)
    playlists_changed: PlaylistsConsumer.PlaylistsChanged = camel_to_dot(PlaylistsConsumer.PlaylistsChanged.__name__)
    rename_playlist: PlaylistsConsumer.RenamePlaylist = camel_to_dot(PlaylistsConsumer.RenamePlaylist.__name__)
    add_playlist: PlaylistsConsumer.AddPlaylist = camel_to_dot(PlaylistsConsumer.AddPlaylist.__name__)
    remove_playlist: PlaylistsConsumer.RemovePlaylist = camel_to_dot(PlaylistsConsumer.RemovePlaylist.__name__)
    add_track: PlaylistRetrieveConsumer.AddTrack = camel_to_dot(PlaylistRetrieveConsumer.AddTrack.__name__)
    remove_track: PlaylistRetrieveConsumer.RemoveTrack = camel_to_dot(PlaylistRetrieveConsumer.RemoveTrack.__name__)


class Examples:
    playlist_changed_response = Action(
        event=str(EventsList.playlists_changed),
        payload=ResponsePayload.Playlist(
            playlist=PlaylistSerializer(None).data,
            change_message='Someone add track to playlist').to_data(),
        system=ActionSystem()
    ).to_data(pop_system=True, to_json=True)

    playlists_changed_response = Action(
        event=str(EventsList.playlists_changed),
        payload=ResponsePayload.Playlists(
            playlists=PlaylistSerializer(None, many=True).data).to_data(),
        system=ActionSystem()
    ).to_data(pop_system=True, to_json=True)

    rename_playlist_request = Action(
        event=str(EventsList.rename_playlist),
        payload=RequestPayload.ModifyPlaylist(playlist_id=1, playlist_name='New name').to_data(),
        system=ActionSystem()
    ).to_data(pop_system=True, to_json=True)

    add_playlist_request = Action(
        event=str(EventsList.add_playlist),
        payload=RequestPayload.ModifyPlaylists(playlist_name='New one name', type=Playlist.Types.public).to_data(),
        system=ActionSystem()
    ).to_data(pop_system=True, to_json=True)

    remove_playlist_request = Action(
        event=str(EventsList.remove_playlist),
        payload=RequestPayload.ModifyPlaylist(playlist_id=1).to_data(),
        system=ActionSystem()
    ).to_data(pop_system=True, to_json=True)

    add_track_request = Action(
        event=str(EventsList.add_track),
        payload=RequestPayload.ModifyPlaylistTracks(track_id=1).to_data(),
        system=ActionSystem()
    ).to_data(pop_system=True, to_json=True)

    remove_track_request = Action(
        event=str(EventsList.remove_track),
        payload=RequestPayload.ModifyPlaylistTracks(track_id=1).to_data(),
        system=ActionSystem()
    ).to_data(pop_system=True, to_json=True)
