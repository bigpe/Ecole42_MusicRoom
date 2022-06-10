from typing import Callable

from django.contrib.auth import get_user_model

from music_room.models import Track, Playlist

User = get_user_model()


class PlaylistService:
    class Decorators:
        @staticmethod
        def lookup_track(f: Callable):
            def wrapper(self, track, *args):
                if isinstance(track, int):
                    track = Track.objects.get(id=track)
                return f(self, track, *args)

            return wrapper

        @staticmethod
        def lookup_playlist(f: Callable):
            def wrapper(self, playlist, *args):
                if isinstance(playlist, int):
                    try:
                        playlist = Playlist.objects.get(id=playlist)
                    except Playlist.DoesNotExist:
                        playlist = None
                return f(self, playlist, *args)

            return wrapper

    @Decorators.lookup_playlist
    def __init__(self, playlist: [int, Playlist]):
        self.playlist: Playlist = playlist

    @Decorators.lookup_track
    def add_track(self, track: [int, Track]):
        self.playlist.tracks.add(track)

    @Decorators.lookup_track
    def remove_track(self, track: [int, Track]):
        self.playlist.tracks.remove(track)

    def rename(self, name: str):
        self.playlist.name = name
        self.playlist.save()
