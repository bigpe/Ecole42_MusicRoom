from django.contrib.auth.password_validation import validate_password
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
        fields = ['id', 'state', 'progress', 'track']


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
    password = serializers.CharField(write_only=True, required=True, validators=[validate_password])

    class Meta:
        model = User
        fields = ['id', 'username', 'password']
        extra_kwargs = {
            'username': {'write_only': True},
            'password': {'write_only': True},
        }

    def create(self, validated_data):
        password = validated_data.get('password')
        user = User.objects.create(**validated_data)
        user.set_password(password)
        user.save()
        return user
