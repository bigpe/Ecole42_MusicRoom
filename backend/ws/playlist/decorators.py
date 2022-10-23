from typing import Callable

from music_room.models import Playlist
from ws.base import BaseEvent, Message
from ws.utils import ActionRef as Action


def get_playlist_from_path(f: Callable):
    def wrapper(self):
        try:
            playlist = Playlist.objects.get(id=int(self.scope['url_route']['kwargs']['playlist_id']))
            return f(self, playlist)
        except Playlist.DoesNotExist:
            self.close()
            self.disconnect(1000)
            return

    return wrapper


def get_playlist(f: Callable):
    def wrapper(self: BaseEvent, message: Message, payload, *args):
        from .consumers import PlaylistRetrieveConsumer
        self.consumer: PlaylistRetrieveConsumer

        try:
            playlist = Playlist.objects.get(id=self.consumer.playlist_id)
            return f(self, message, payload, playlist, *args)
        except Playlist.DoesNotExist:
            return Action(event='error', payload={'message': 'Playlist not found'}, system=message.system.to_data())

    return wrapper


def only_for_author(f: Callable):
    def wrapper(self, playlist: Playlist):
        from ws.playlist.consumers import PlaylistRetrieveConsumer
        self: PlaylistRetrieveConsumer

        if self.get_user() != playlist.author:
            self.close()
            self.disconnect(1000)
            return
        return f(self, playlist)
    return wrapper