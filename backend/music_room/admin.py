from django.contrib import admin
from .models import SessionTrack, PlayerSession, Playlist, PlaylistAccess, Track

admin.site.register(SessionTrack)
admin.site.register(PlayerSession)
admin.site.register(Track)


class PlaylistAccessInline(admin.StackedInline):
    model = PlaylistAccess
    extra = 0


@admin.register(Playlist)
class PlaylistAdmin(admin.ModelAdmin):
    inlines = [PlaylistAccessInline]
