from django.contrib.auth import get_user_model, authenticate, login
from django.db.models import Q
from drf_yasg.utils import swagger_auto_schema
from rest_framework.generics import ListAPIView, RetrieveAPIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

from .models import Track, Playlist, PlayerSession
from .serializers import TrackSerializer, PlaylistSerializer, PlayerSessionSerializer, UserSerializer, \
    TokenObtainPairSerializer, TokenRefreshSerializer, TokenResponseSerializer

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
    queryset = Playlist.objects.filter(access_type=Playlist.AccessTypes.public).all()
    serializer_class = PlaylistSerializer

    def get_queryset(self):
        if not self.request.user.is_authenticated:
            return self.queryset.all()
        return Playlist.objects.filter(
            Q(access_type=Playlist.AccessTypes.public) | Q(access_users__user__in=[self.request.user])
        )


class PlaylistOwnListView(ListAPIView):
    """
    Playlists own

    Get current authed user own playlists
    """
    queryset = Playlist.objects.filter(access_type=Playlist.AccessTypes.public).all()
    serializer_class = PlaylistSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
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
    serializer_class = TokenObtainPairSerializer

    @swagger_auto_schema(responses={200: TokenResponseSerializer()})
    def post(self, request, *args, **kwargs):
        user = authenticate(**request.data)
        if not user:
            user_serializer = UserSerializer(data=request.data)
            if not user_serializer.is_valid():
                return Response(user_serializer.errors)
            user = user_serializer.create(request.data)
        login(request, user)
        return super(AuthView, self).post(request, *args, **kwargs)


class TokenRefreshWithExpiresView(TokenRefreshView):
    """
    Refresh token

    Refresh already created access token by refresh token
    """
    serializer_class = TokenRefreshSerializer

    @swagger_auto_schema(responses={200: TokenResponseSerializer()})
    def post(self, request, *args, **kwargs):
        return super(TokenRefreshWithExpiresView, self).post(request, *args, **kwargs)


class UserListView(ListAPIView):
    """
    Users

    Get users list
    """
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return User.objects.exclude(username=self.request.user.username)
