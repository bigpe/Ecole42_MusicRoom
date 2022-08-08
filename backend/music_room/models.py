import os
from typing import List, Union

from tinytag import TinyTag
from pydub import AudioSegment
from django.contrib.auth.models import AbstractUser
from django.core.exceptions import ValidationError
from django.db import models
from django.db.models.fields.files import FieldFile
from django.db.models.manager import Manager
from django.db.models.signals import post_save, post_delete
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
    # allowed_extensions = File.Extensions.names
    allowed_extensions = File.Extensions.names
    file_extension = file.name.split('.')[-1]
    if file_extension not in allowed_extensions:
        raise ValidationError(
            'Audio file wrong extension',
            params={'value': file_extension},
        )


class Track(models.Model):
    name = models.CharField(max_length=150, unique=True)  #: Track name

    # files: File

    def __str__(self):
        return self.name


class File(models.Model):
    class Extensions(models.TextChoices):
        mp3 = 'mp3'
        flac = 'flac'

    #: Track file
    file = models.FileField(
        upload_to='music',
        validators=[audio_file_validator],
        help_text=f'Send highest quality file, lowest will be make automatically<br>'
                  f'Allowed:<br> {"<br>".join(Extensions.names)}'
    )
    #: Track file extension
    extension: Extensions = models.CharField(max_length=50, choices=Extensions.choices, blank=True, null=True)
    #: Track duration in seconds
    duration = models.FloatField(blank=True, null=True)
    #: Track instance
    track = models.ForeignKey(Track, models.CASCADE, related_name='files')

    def __str__(self):
        return f'{self.track.name} - {self.extension}'


@receiver(post_save, sender=File)
def file_post_save(instance: File, created, *args, **kwargs):
    post_save.disconnect(file_post_save, sender=File)
    if instance.file:
        file_extension = instance.file.name.split('.')[-1]
        track_file_meta = TinyTag.get(instance.file.path)
        instance.duration = track_file_meta.duration
        instance.extension = file_extension
        instance.save()
        mp3_path = instance.file.path.replace('.flac', '.mp3')
        mp3_name = instance.file.name.replace('.flac', '.mp3')
        _, export_not_exist = File.objects.get_or_create(
            id=instance.id + 1,
            track=instance.track,
            duration=instance.duration,
            extension=File.Extensions.mp3,
            file=mp3_name
        )
        if export_not_exist:
            flac_audio = AudioSegment.from_file(instance.file.path, file_extension)
            flac_audio.export(mp3_path, format='mp3')
        print('+', mp3_name, 'Exported')
    post_save.connect(file_post_save, sender=File)


@receiver(post_delete, sender=File)
def file_post_delete(instance: File, *args, **kwargs):
    try:
        os.unlink(instance.file.path)
    except FileNotFoundError:
        ...


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

    def __str__(self):
        return f"{self.author}'s playlist"


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
