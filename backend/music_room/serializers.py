from rest_framework import serializers

from .models import Track, Playlist, PlayerSession, SessionTrack, PlaylistTrack, PlaylistAccess, User


class TrackSerializer(serializers.ModelSerializer):
    class Meta:
        model = Track
        fields = '__all__'


class PlaylistTrackSerializer(serializers.ModelSerializer):
    class Meta:
        model = PlaylistTrack
        fields = '__all__'


class PlaylistSerializer(serializers.ModelSerializer):
    tracks = PlaylistTrackSerializer(many=True)

    class Meta:
        model = Playlist
        fields = '__all__'


class SessionTrackSerializer(serializers.ModelSerializer):
    class Meta:
        model = SessionTrack
        fields = ['state', 'id']


class PlayerSessionSerializer(serializers.ModelSerializer):
    track_queue = SessionTrackSerializer(many=True)

    class Meta:
        model = PlayerSession
        fields = '__all__'


class PlaylistAccessSerializer(serializers.ModelSerializer):
    class Meta:
        model = PlaylistAccess
        fields = '__all__'


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'password']
        extra_kwargs = {
            'username': {'write_only': True},
            'password': {'write_only': True},
        }
