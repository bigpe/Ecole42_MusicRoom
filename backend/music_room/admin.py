from django.contrib import admin
from .models import SessionTrack, PlayerSession, Playlist, PlaylistAccess, Track, User, File

admin.site.register(SessionTrack)
admin.site.register(PlayerSession)
admin.site.register(User)
admin.site.register(File)


class PlaylistAccessInline(admin.StackedInline):
    model = PlaylistAccess
    extra = 0


class FileInline(admin.StackedInline):
    model = File
    extra = 0


@admin.register(Playlist)
class PlaylistAdmin(admin.ModelAdmin):
    inlines = [PlaylistAccessInline]


@admin.register(Track)
class TrackAdmin(admin.ModelAdmin):
    inlines = [FileInline]
