import uuid
from datetime import timedelta

from django.conf import settings
from django.contrib.auth.password_validation import validate_password
from django.utils import timezone
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenRefreshSerializer as TokenRefreshBaseSerializer, \
    TokenObtainPairSerializer as TokenObtainPairBaseSerializer

from .models import Track, Playlist, PlayerSession, SessionTrack, PlaylistTrack, PlaylistAccess, User, TrackFile, \
    Artist, Event


class FileSerializer(serializers.ModelSerializer):
    class Meta:
        model = TrackFile
        fields = '__all__'


class TrackSerializer(serializers.ModelSerializer):
    files = FileSerializer(many=True)

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
            # 'username': {'write_only': True},
            'password': {'write_only': True},
        }

    def create(self, validated_data):
        password = validated_data.get('password')
        user = User.objects.create(**validated_data)
        user.set_password(password)
        user.save()
        return user


class TokenExpiresMixin:
    expires_in = serializers.DateTimeField(required=False)

    def validate(self, attrs):
        data = super(TokenExpiresMixin, self).validate(attrs)
        expires_in = timezone.now() + getattr(
            settings, 'SIMPLE_JWT', {}
        ).get('ACCESS_TOKEN_LIFETIME', timedelta(minutes=5))
        data.update({'expires_in': expires_in})
        return data


class TokenObtainPairSerializer(TokenExpiresMixin, TokenObtainPairBaseSerializer):
    ...


class TokenRefreshSerializer(TokenExpiresMixin, TokenRefreshBaseSerializer):
    ...


class TokenResponseSerializer(serializers.Serializer):
    expires_in = serializers.DateTimeField()
    refresh = serializers.CharField()
    access = serializers.CharField()


class ArtistSerializer(serializers.ModelSerializer):
    tracks = TrackSerializer(many=True)

    class Meta:
        model = Artist
        fields = '__all__'


class EventCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Event
        fields = '__all__'
        extra_kwargs = {
            'author': {'read_only': True},
        }

    def create(self, validated_data):
        author = self.context.get('request').user
        validated_data.update({'author': author})
        scratch_playlist: Playlist = validated_data.get('playlist')
        playlist = Playlist.objects.create(
            type=Playlist.Types.temporary,
            name=str(uuid.uuid4()),
            author=author
        )
        validated_data.update({'playlist': playlist})
        # Clone tracks
        if scratch_playlist:
            for track in scratch_playlist.tracks.all():
                track: PlaylistTrack
                PlaylistTrack.objects.create(
                    track=track.track,
                    order=track.order,
                    playlist=playlist
                )
        return Event.objects.create(**validated_data)


class EventListSerializer(serializers.ModelSerializer):
    class Meta:
        model = Event
        fields = '__all__'
