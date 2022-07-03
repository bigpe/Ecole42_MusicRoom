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

        @staticmethod
        def lookup_user(f: Callable):
            def wrapper(self, user, *args):
                if isinstance(user, int):
                    try:
                        user = User.objects.get(id=user)
                    except Playlist.DoesNotExist:
                        user = None
                return f(self, user, *args)

            return wrapper

    @Decorators.lookup_playlist
    def __init__(self, playlist: [int, Playlist]):
        self.playlist: Playlist = playlist

    @Decorators.lookup_track
    def add_track(self, track: [int, Track]):
        self.playlist.tracks.create(track=track, order=0)

    @Decorators.lookup_track
    def remove_track(self, track: [int, Track]):
        self.playlist.tracks.filter(track=track).delete()

    def change(self, name: str = None, access_type: [str, Playlist.AccessTypes] = None):
        if not name:
            name = self.playlist.name
        if not access_type:
            access_type = self.playlist.access_type
        self.playlist.name = name
        self.playlist.access_type = access_type
        self.playlist.save()

    @Decorators.lookup_user
    def invite_user(self, user: User):
        self.playlist.access_users.add(user)

    @Decorators.lookup_user
    def revoke_user(self, user: User):
        self.playlist.access_users.filter(user=user).delete()

    def change_access_type(self, access_type: Playlist.AccessTypes):
        self.playlist.access_type = access_type
        self.playlist.save()
