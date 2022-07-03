from django.contrib.auth import get_user_model, authenticate
from django.db.models import Q
from drf_yasg.utils import swagger_auto_schema
from rest_framework.generics import ListAPIView, RetrieveAPIView, CreateAPIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework_simplejwt.serializers import TokenRefreshSerializer, TokenObtainPairSerializer
from rest_framework_simplejwt.views import TokenObtainPairView, TokenViewBase

from .models import Track, Playlist, PlayerSession
from .serializers import TrackSerializer, PlaylistSerializer, PlayerSessionSerializer, UserSerializer

User = get_user_model()


class TrackListView(ListAPIView):
    """
    Tracks

    Get all tracks
    """
    queryset = Track.objects.all()
    serializer_class = TrackSerializer


class PlaylistListView(ListAPIView):
    """
    Playlists

    Get accessed playlists
    """
    queryset = Playlist.objects.filter(type=Playlist.Types.public).all()
    serializer_class = PlaylistSerializer

    def get_queryset(self):
        if not self.request.user.is_authenticated:
            return self.queryset.all()
        return Playlist.objects.filter(Q(type=Playlist.Types.public) | Q(access_users__user__in=[self.request.user]))


class PlaylistOwnListView(ListAPIView):
    """
    Playlists own

    Get current authed user own playlists
    """
    queryset = Playlist.objects.filter(type=Playlist.Types.public).all()
    serializer_class = PlaylistSerializer

    def get_queryset(self):
        if not self.request.user.is_authenticated:
            return self.queryset.all()
        return Playlist.objects.filter(author=self.request.user)


class PlayerSessionRetrieveView(RetrieveAPIView):
    """
    Player Session

    Get current authed user player session
    """
    queryset = PlayerSession.objects.all()
    serializer_class = PlayerSessionSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        return PlayerSession.objects.filter(author=self.request.user).first()


class AuthView(TokenObtainPairView):
    """
    Auth

    Login or Register new profile (if not exist) and get access and refresh token
    """

    @swagger_auto_schema(responses={200: TokenRefreshSerializer()})
    def post(self, request, *args, **kwargs):
        user = authenticate(**request.data)
        if not user:
            user_serializer = UserSerializer(data=request.data)
            if not user_serializer.is_valid():
                return Response(user_serializer.errors)
            user_serializer.create(request.data)
        return super(AuthView, self).post(request, *args, **kwargs)
