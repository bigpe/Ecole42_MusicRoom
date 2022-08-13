from django.contrib import admin
from .models import Playlist, PlaylistAccess, Track, User, TrackFile, PlaylistTrack, Artist

admin.site.register(User)


class PlaylistAccessInline(admin.StackedInline):
    model = PlaylistAccess
    extra = 0


class PlaylistTrackInline(admin.StackedInline):
    model = PlaylistTrack
    extra = 0


class TrackInline(admin.StackedInline):
    model = Track
    extra = 0


class FileInline(admin.StackedInline):
    model = TrackFile
    extra = 1
    max_num = 1
    readonly_fields = ['duration', 'extension']


@admin.register(Playlist)
class PlaylistAdmin(admin.ModelAdmin):
    inlines = [PlaylistAccessInline, PlaylistTrackInline]
    list_display = ['name', 'author', 'tracks', 'access_users', 'access_type']
    list_filter = ['access_type']

    @admin.display
    def tracks(self, instance: Playlist):
        return [playlist_track.track.name for playlist_track in instance.tracks.all()]

    @admin.display
    def access_users(self, instance: Playlist):
        return [access_users for access_users in instance.access_users.all()]


@admin.register(Artist)
class ArtistAdmin(admin.ModelAdmin):
    list_display = ['name', 'tracks']
    inlines = [TrackInline]

    @admin.display
    def tracks(self, instance: Artist):
        return [track for track in instance.tracks.all()]


@admin.register(Track)
class TrackAdmin(admin.ModelAdmin):
    list_display = ['name', 'artist']
    inlines = [FileInline]
