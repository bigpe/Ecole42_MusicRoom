from django.contrib.auth.models import User
from django.db import models

from bootstrap.utils import BootstrapMixin


class Track(models.Model, BootstrapMixin):
    name = models.CharField(max_length=150)
    order = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ['order']


class Playlist(models.Model, BootstrapMixin):
    class Types:
        public = 'public'
        private = 'private'

    TypesChoice = (
        (Types.public, 'Public'),
        (Types.private, 'Private'),
    )

    name = models.CharField(max_length=150)
    type = models.CharField(max_length=50, choices=TypesChoice, default=Types.public)
    tracks = models.ManyToManyField(Track)
    # access_users: PlaylistAccess


class PlaylistAccess(models.Model, BootstrapMixin):
    user = models.ForeignKey(User, models.CASCADE)
    playlist = models.ForeignKey(Playlist, models.CASCADE, related_name='access_users')


class SessionTrack(models.Model, BootstrapMixin):
    class States:
        stopped = 'stopped'
        playing = 'playing'
        paused = 'paused'

    StatesChoice = (
        (States.stopped, 'Stopped'),
        (States.playing, 'Playing'),
        (States.paused, 'Paused'),
    )

    state = models.CharField(max_length=50, choices=StatesChoice, default=StatesChoice[0])
    track = models.ForeignKey(Track, models.CASCADE)
    votes = models.ManyToManyField(User)
    votes_count = models.PositiveIntegerField(default=0)
    order = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ['-votes_count', 'order']

    def __str__(self):
        return f'{self.id}-{self.order}'


class PlaySession(models.Model, BootstrapMixin):
    class Modes:
        repeat = 'repeat'
        normal = 'normal'

    ModeChoice = (
        (Modes.normal, 'Normal'),
        (Modes.repeat, 'Repeat one song'),
    )

    playlist = models.ForeignKey(Playlist, models.CASCADE)
    track_queue = models.ManyToManyField(SessionTrack)
    mode = models.CharField(max_length=50, choices=ModeChoice, default=ModeChoice[0])
