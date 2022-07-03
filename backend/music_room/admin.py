from django.contrib import admin
from .models import SessionTrack, PlayerSession, Playlist, PlaylistAccess, Track, User

admin.site.register(SessionTrack)
admin.site.register(PlayerSession)
admin.site.register(Track)
admin.site.register(User)


class PlaylistAccessInline(admin.StackedInline):
    model = PlaylistAccess
    extra = 0


@admin.register(Playlist)
class PlaylistAdmin(admin.ModelAdmin):
    inlines = [PlaylistAccessInline]
