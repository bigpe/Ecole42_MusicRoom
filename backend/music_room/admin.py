from django.contrib import admin
from .models import Playlist, PlaylistAccess, Track, User, TrackFile, PlaylistTrack, Artist, EventAccess, Event, PlayerSession

admin.site.register(User)
admin.site.register(PlayerSession)


class PlaylistAccessInline(admin.StackedInline):
    model = PlaylistAccess
    extra = 0


class EventAccessInline(admin.StackedInline):
    model = EventAccess
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
    list_display = ['name', 'author', 'tracks', 'playlist_access_users', 'access_type']
    list_filter = ['access_type']

    @admin.display
    def tracks(self, instance: Playlist):
        return [playlist_track.track.name for playlist_track in instance.tracks.all()]

    @admin.display
    def playlist_access_users(self, instance: Playlist):
        return [playlist_access_users for playlist_access_users in instance.playlist_access_users.all()]


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


@admin.register(Event)
class EventAdmin(admin.ModelAdmin):
    inlines = [EventAccessInline]
    list_display = ['name', 'author', 'event_access_users', 'access_type']
    list_filter = ['access_type']

    @admin.display
    def event_access_users(self, instance: Event):
        return [event_access_users for event_access_users in instance.event_access_users.all()]
