from typing import List, Union

import eyed3 as eyed3
from django.contrib.auth.models import AbstractUser
from django.core.exceptions import ValidationError
from django.db import models
from django.db.models.fields.files import FieldFile
from django.db.models.manager import Manager
from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver

from bootstrap.utils import BootstrapMixin, BootstrapGeneric, AUDIO_PLACEHOLDER


class User(AbstractUser):
    ...
    # playlists: PlaylistChanged


@receiver(post_save, sender=User)
def user_post_save(instance: User, created, **kwargs):
    if not created:
        return

    favourites_playlist = Playlist.objects.create(name='Favourites', type=Playlist.Types.private, author=instance)
    instance.playlists.add(favourites_playlist)


def audio_file_validator(file: FieldFile):
    file_extension = file.name.split('.')[-1]
    if not file_extension == 'mp3':
        raise ValidationError(
            'Audio file wrong extension',
            params={'value': file_extension},
        )


class Track(models.Model):
    name = models.CharField(max_length=150, unique=True)  #: Track name
    track_file = models.FileField(upload_to='music', validators=[audio_file_validator])  #: Track file
    track_duration = models.FloatField(blank=True, null=True)  #: Track duration in seconds

    def __str__(self):
        return self.name


@receiver(post_save, sender=Track)
def track_post_save(instance: Track, created, *args, **kwargs):
    post_save.disconnect(track_post_save, sender=Track)
    if instance.track_file:
        track_file_meta = eyed3.load(instance.track_file.path)
        instance.track_duration = track_file_meta.info.time_secs
        instance.save()
    post_save.connect(track_post_save, sender=Track)


class PlaylistTrack(models.Model, BootstrapMixin):
    track: Track = models.ForeignKey(Track, models.CASCADE)  #: Track object
    order: int = models.PositiveIntegerField(default=0)  #: Track order in playlist

    class Meta:
        ordering = ['order']


class Playlist(models.Model, BootstrapMixin):
    class Types:
        public = 'public'  #: Everyone can access
        private = 'private'  #: Only invited users can access

    TypesChoice = (
        (Types.public, 'Public'),
        (Types.private, 'Private'),
    )

    #: PlaylistChanged name
    name = models.CharField(max_length=150)
    #: PlaylistChanged type
    type: Types = models.CharField(max_length=50, choices=TypesChoice, default=Types.public)
    #: PlaylistChanged`s tracks
    tracks: Union[List[PlaylistTrack], Manager] = models.ManyToManyField(PlaylistTrack)
    #: PlaylistChanged`s author
    author: User = models.ForeignKey(User, models.CASCADE, related_name='playlists')
    # access_users: PlaylistAccess


class PlaylistAccess(models.Model, BootstrapMixin):
    user = models.ForeignKey(User, models.CASCADE)
    playlist = models.ForeignKey(Playlist, models.CASCADE, related_name='access_users')


class SessionTrack(models.Model):
    class States:
        stopped = 'stopped'
        playing = 'playing'
        paused = 'paused'

    StatesChoice = (
        (States.stopped, 'Stopped'),
        (States.playing, 'Playing'),
        (States.paused, 'Paused'),
    )

    #: Session track state
    state: States = models.CharField(max_length=50, choices=StatesChoice, default=States.stopped)
    #: Track object
    track: Track = models.ForeignKey(Track, models.CASCADE)
    #: Votes user for next play
    votes: Union[List[User], Manager] = models.ManyToManyField(User)
    #: Votes count for next play
    votes_count: int = models.PositiveIntegerField(default=0)
    #: Tracks order in queue
    order: int = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ['-votes_count', 'order']

    def __str__(self):
        return f'{self.track.id}-{self.state}-{self.order}'

    class Bootstrap(BootstrapGeneric):
        state = 'stopped'
        votes_count = 0


class PlayerSession(models.Model, BootstrapMixin):
    class Modes:
        repeat = 'repeat'  #: Repeat single track for loop
        normal = 'normal'  #: Normal mode, tracks play in usual order

    ModeChoice = (
        (Modes.normal, 'Normal'),
        (Modes.repeat, 'Repeat one song'),
    )

    #: PlaylistChanged object
    playlist: Union[Playlist, Manager] = models.ForeignKey(Playlist, models.CASCADE)
    #: Track queue
    track_queue: Union[List[SessionTrack], Manager] = models.ManyToManyField(SessionTrack)
    #: Player Session mode
    mode: Modes = models.CharField(max_length=50, choices=ModeChoice, default=Modes.normal)
    #: Player Session author
    author: User = models.ForeignKey(User, models.CASCADE)

    class Bootstrap(BootstrapGeneric):
        @staticmethod
        def after_bootstrap(model):
            for i, track in enumerate(model.track_queue.all()):
                track.order = i
                track.save()


@receiver(post_save, sender=PlayerSession)
def player_session_post_save(instance: PlayerSession, created, **kwargs):
    if not created:
        return

    PlayerSession.objects.filter(author=instance.author).exclude(id=instance.id).delete()

    playlist_tracks: List[PlaylistTrack] = instance.playlist.tracks.all()
    for i, playlist_track in enumerate(playlist_tracks):
        session_track = SessionTrack.objects.create(track=playlist_track.track, order=i)
        instance.track_queue.add(session_track)
