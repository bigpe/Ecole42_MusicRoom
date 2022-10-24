import random
from functools import wraps
from typing import Callable

from django.contrib.auth import get_user_model

from music_room.models import PlayerSession, SessionTrack, Track

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
        def lookup_session_track(f: Callable):
            @wraps(f)
            def wrapper(self, track, *args):
                if isinstance(track, int):
                    track = SessionTrack.objects.get(id=track)
                return f(self, track, *args)

            return wrapper

        @staticmethod
        def lookup_track(f: Callable):
            @wraps(f)
            def wrapper(self, track, *args):
                if isinstance(track, int):
                    track = Track.objects.get(id=track)
                return f(self, track, *args)

            return wrapper

    @Decorators.lookup_player_session
    def __init__(self, player_session: [int, PlayerSession]):
        self.player_session: PlayerSession = player_session

    @staticmethod
    def vote(track: [int, SessionTrack], user: User):
        if isinstance(track, int):
            track = SessionTrack.objects.get(id=track)
        track.votes.remove(user) if user in track.votes.all() else track.votes.add(user)
        track.votes_count = track.votes.all().count()
        # If only one vote, is not affect the queue
        if track.votes_count == 1:
            track.votes_count = 0
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

    def reset_tracks_votes(self):
        for track in self.player_session.track_queue.all():
            track: SessionTrack
            track.votes.clear()
            track.votes_count = 0
            track.save()

    @Decorators.lookup_session_track
    def play_track(self, track: [int, SessionTrack]) -> SessionTrack:
        first_track = self.current_track
        next_track = track
        last_track = self.previous_track

        reverse = next_track == last_track

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
        self.reset_tracks_votes()
        self.resort()
        return track

    @Decorators.lookup_session_track
    def delay_play_track(self, track: [int, SessionTrack]) -> SessionTrack:
        self.current_track.order = -1
        track.order = 0
        self.current_track.save()
        track.save()

        self.resort()
        return track

    @property
    def previous_track(self) -> SessionTrack:
        return self.player_session.track_queue.last()

    @property
    def current_track(self) -> SessionTrack:
        return self.player_session.track_queue.first()

    @property
    def next_track(self) -> SessionTrack:
        if self.player_session.track_queue.all().count() >= 2:
            return self.player_session.track_queue.all()[1]
        else:
            return self.current_track

    def shuffle(self):
        if self.current_track:
            tracks = list(self.player_session.playlist.tracks.exclude(track=self.current_track.track).all())
            self.player_session.track_queue.exclude(order=self.current_track.order).all().delete()
        else:
            tracks = list(self.player_session.playlist.tracks.all())
        for i in range(len(tracks)):
            random_track = random.choice(tracks)
            session_track = SessionTrack.objects.create(
                track=tracks.pop(tracks.index(random_track)).track,
                order=i + 1
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

    @Decorators.lookup_track
    def add_track(self, track: [int, Track]):
        session_track = SessionTrack.objects.create(
            track=track,
            order=self.player_session.track_queue.all().count()
        )
        self.player_session.track_queue.add(session_track)

    @Decorators.lookup_session_track
    def remove_track(self, track: [int, SessionTrack]):
        self.player_session.track_queue.remove(track)
