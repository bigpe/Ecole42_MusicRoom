from django.contrib import admin

from .models import SessionTrack, PlayerSession, Playlist, PlaylistAccess

admin.site.register(SessionTrack)
admin.site.register(PlayerSession)


class PlaylistAccessInline(admin.StackedInline):
    model = PlaylistAccess
    extra = 0


@admin.register(Playlist)
class PlaylistAdmin(admin.ModelAdmin):
    inlines = [PlaylistAccessInline]
