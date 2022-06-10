from django.contrib import admin

from .models import SessionTrack, PlaySession, Playlist

admin.site.register(SessionTrack)
admin.site.register(PlaySession)
admin.site.register(Playlist)
