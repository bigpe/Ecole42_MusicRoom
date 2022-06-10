from rest_framework import serializers

from .models import Track, Playlist, PlaySession, SessionTrack


class TrackSerializer(serializers.ModelSerializer):
    class Meta:
        model = Track
        fields = '__all__'


class PlaylistSerializer(serializers.ModelSerializer):
    tracks = TrackSerializer(many=True)

    class Meta:
        model = Playlist
        fields = '__all__'


class SessionTrackSerializer(serializers.ModelSerializer):
    class Meta:
        model = SessionTrack
        fields = ['state', 'id']


class PlaySessionSerializer(serializers.ModelSerializer):
    track_queue = SessionTrackSerializer(many=True)

    class Meta:
        model = PlaySession
        fields = '__all__'
