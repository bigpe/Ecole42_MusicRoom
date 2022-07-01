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
            self.close(code=401)
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
