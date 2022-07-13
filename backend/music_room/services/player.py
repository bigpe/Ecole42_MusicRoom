import random
from functools import wraps
from typing import Callable

from django.contrib.auth import get_user_model

from music_room.models import PlayerSession, SessionTrack

User = get_user_model()


class PlayerService:
    class Decorators:
        @staticmethod
        def lookup_player_session(f: Callable):
            def wrapper(self, player_session, *args):
                if isinstance(player_session, int):
                    try:
                        player_session = PlayerSession.objects.get(id=player_session)
                    except PlayerSession.DoesNotExist:
                        player_session = None
                return f(self, player_session, *args)

            return wrapper

        @staticmethod
        def lookup_track(f: Callable):
            @wraps(f)
            def wrapper(self, track, *args):
                if isinstance(track, int):
                    track = SessionTrack.objects.get(id=track)
                return f(self, track, *args)

            return wrapper

    @Decorators.lookup_player_session
    def __init__(self, player_session: [int, PlayerSession]):
        self.player_session: PlayerSession = player_session

    @staticmethod
    def vote(track: SessionTrack, user: User):
        track.votes.remove(user) if user in track.votes.all() else track.votes.add(user)
        track.votes_count = track.votes.all().count()
        track.save()

    def play_next(self) -> SessionTrack:
        if self.player_session.mode == self.player_session.Modes.repeat:
            return self.play_track(self.current_track)
        return self.play_track(self.next_track)

    def play_previous(self) -> SessionTrack:
        if self.player_session.mode == self.player_session.Modes.repeat:
            return self.play_track(self.current_track)
        return self.play_track(self.previous_track)

    def reset_tracks_progress(self):
        for track in self.player_session.track_queue.filter(progress__gt=0).all():
            track: SessionTrack
            track.progress = 0
            track.save()

    @Decorators.lookup_track
    def play_track(self, track: [int, SessionTrack]) -> SessionTrack:
        first_track = self.current_track
        next_track = track
        last_track = self.previous_track

        reverse = False
        if next_track == last_track:
            reverse = True

        next_track.order = -1
        if not reverse:
            first_track.order = self.player_session.track_queue.all().count()

        first_track.state = SessionTrack.States.stopped
        next_track.state = SessionTrack.States.playing
        next_track.save()
        first_track.save()
        last_track.save()
        track.save()

        self.reset_tracks_progress()
        self.resort()
        return track

    @property
    def previous_track(self) -> SessionTrack:
        return self.player_session.track_queue.last()

    @property
    def current_track(self) -> SessionTrack:
        return self.player_session.track_queue.order_by('order').first()

    @property
    def next_track(self) -> SessionTrack:
        if self.player_session.track_queue.all().count() >= 2:
            return self.player_session.track_queue.all()[1]
        else:
            return self.current_track

    def shuffle(self):
        tracks = list(self.player_session.playlist.tracks.all())
        self.player_session.track_queue.all().delete()
        for i in range(len(tracks)):
            random_track = random.choice(tracks)
            session_track = SessionTrack.objects.create(
                track=tracks.pop(tracks.index(random_track)).track,
                order=i
            )
            self.player_session.track_queue.add(session_track)

    def pause_track(self):
        track: SessionTrack = self.current_track
        track.state = SessionTrack.States.paused
        track.save()

    def resume_track(self):
        track: SessionTrack = self.current_track
        track.state = SessionTrack.States.playing
        track.save()

    def stop_track(self):
        track: SessionTrack = self.current_track
        track.state = SessionTrack.States.stopped
        track.save()

    def freeze_session(self):
        track: SessionTrack = self.player_session.track_queue.filter(state=SessionTrack.States.playing).first()
        if track:
            track.state = SessionTrack.States.paused
            track.save()

    def sync_track(self, progress: float):
        track: SessionTrack = self.current_track
        track.progress = progress
        track.save()

    def resort(self):
        for i, track in enumerate(self.player_session.track_queue.all()):
            track.order = i
            track.save()
