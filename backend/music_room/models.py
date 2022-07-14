from typing import List, Union

import eyed3 as eyed3
from django.contrib.auth.models import AbstractUser
from django.core.exceptions import ValidationError
from django.db import models
from django.db.models.fields.files import FieldFile
from django.db.models.manager import Manager
from django.db.models.signals import post_save
from django.dispatch import receiver

from bootstrap.utils import BootstrapMixin


class User(AbstractUser, BootstrapMixin):
    ...
    # playlists: PlaylistChanged


@receiver(post_save, sender=User)
def user_post_save(instance: User, created, **kwargs):
    if not created:
        return

    favourites_playlist = Playlist.objects.create(
        name='Favourites',
        type=Playlist.Types.default,
        access_type=Playlist.AccessTypes.private,
        author=instance
    )
    instance.playlists.add(favourites_playlist)


def audio_file_validator(file: FieldFile):
    allowed_extensions = ['mp3', 'flac']
    file_extension = file.name.split('.')[-1]
    if file_extension not in allowed_extensions:
        raise ValidationError(
            'Audio file wrong extension',
            params={'value': file_extension},
        )


class Track(models.Model):
    name = models.CharField(max_length=150, unique=True)  #: Track name
    file = models.FileField(upload_to='music', validators=[audio_file_validator])  #: Track file
    duration = models.FloatField(blank=True, null=True)  #: Track duration in seconds

    def __str__(self):
        return self.name


@receiver(post_save, sender=Track)
def track_post_save(instance: Track, created, *args, **kwargs):
    post_save.disconnect(track_post_save, sender=Track)
    if instance.file:
        track_file_meta = eyed3.load(instance.file.path)
        instance.duration = track_file_meta.info.time_secs
        instance.save()
    post_save.connect(track_post_save, sender=Track)


class Playlist(models.Model):
    class Types:
        default = 'default'  #: Default playlist e.g. favourites
        custom = 'custom'  #: Custom playlist, created by user

    TypesChoice = (
        (Types.default, 'Default'),
        (Types.custom, 'Custom'),
    )

    class AccessTypes:
        public = 'public'  #: Everyone can access
        private = 'private'  #: Only invited users can access

    AccessTypesChoice = (
        (AccessTypes.public, 'Public'),
        (AccessTypes.private, 'Private'),
    )

    #: Playlist name
    name = models.CharField(max_length=150)
    #: Playlist type
    type: Types = models.CharField(max_length=50, choices=TypesChoice, default=Types.custom)
    #: Playlist access type
    access_type: AccessTypes = models.CharField(max_length=50, choices=AccessTypesChoice, default=AccessTypes.public)
    #: Playlist`s author
    author: User = models.ForeignKey(User, models.CASCADE, related_name='playlists')
    # access_users: PlaylistAccess
    # tracks: PlaylistTrack


class PlaylistTrack(models.Model):
    track: Track = models.ForeignKey(Track, models.CASCADE)  #: Track object
    order: int = models.IntegerField(default=0)  #: Track order in playlist
    playlist = models.ForeignKey(Playlist, models.CASCADE, related_name='tracks')

    class Meta:
        ordering = ['order']


class PlaylistAccess(models.Model):
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
    #: Track time progress from duration
    progress = models.FloatField(default=0)
    #: Tracks order in queue
    order: int = models.IntegerField(default=0)

    class Meta:
        ordering = ['-votes_count', 'order']

    def __str__(self):
        return f'{self.track.name}-{self.state}-{self.order}'


class PlayerSession(models.Model):
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


@receiver(post_save, sender=PlayerSession)
def player_session_post_save(instance: PlayerSession, created, **kwargs):
    if not created:
        return

    PlayerSession.objects.filter(author=instance.author).exclude(id=instance.id).delete()

    playlist_tracks: List[PlaylistTrack] = instance.playlist.tracks.all()
    for i, playlist_track in enumerate(playlist_tracks):
        session_track = SessionTrack.objects.create(track=playlist_track.track, order=i)
        instance.track_queue.add(session_track)

