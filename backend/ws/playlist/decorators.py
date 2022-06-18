from typing import Callable

from music_room.models import Playlist


def get_playlist(f: Callable):
    def wrapper(self):
        try:
            playlist = Playlist.objects.get(id=int(self.scope['url_route']['kwargs']['playlist_id']))
            return f(self, playlist)
        except Playlist.DoesNotExist:
            self.close(code=401)
            return

    return wrapper
