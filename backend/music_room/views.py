from rest_framework.generics import ListAPIView

from .models import Track, Playlist
from .serializers import TrackSerializer, PlaylistSerializer


class TrackListView(ListAPIView):
    queryset = Track.objects.all()
    serializer_class = TrackSerializer


class PlaylistListView(ListAPIView):
    queryset = Playlist.objects.all()
    serializer_class = PlaylistSerializer
