from django.contrib import admin
from .models import SessionTrack, PlayerSession, Playlist, PlaylistAccess, Track, User, TrackFile, PlaylistTrack

admin.site.register(SessionTrack)
admin.site.register(PlayerSession)
admin.site.register(User)
admin.site.register(TrackFile)


class PlaylistAccessInline(admin.StackedInline):
    model = PlaylistAccess
    extra = 0


class PlaylistTrackInline(admin.StackedInline):
    model = PlaylistTrack
    extra = 0


class FileInline(admin.StackedInline):
    model = TrackFile
    extra = 0
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


@admin.register(Track)
class TrackAdmin(admin.ModelAdmin):
    inlines = [FileInline]
