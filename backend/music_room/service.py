import random
from typing import Callable

from django.contrib.auth.models import User

from .models import PlaySession, SessionTrack


def lookup_play_session(f: Callable):
    def wrapper(self, play_session, *args):
        if isinstance(play_session, int):
            play_session = PlaySession.objects.get(id=play_session)
        return f(self, play_session, *args)

    return wrapper


def lookup_track(f: Callable):
    def wrapper(*args, **kwargs):
        self = args[0]
        track = args[1]
        if isinstance(track, int):
            track = SessionTrack.objects.get(id=track)
        return f(self, track)

    return wrapper


class Player:
    @lookup_play_session
    def __init__(self, play_session: [int, PlaySession]):
        self.play_session: PlaySession = play_session

    @staticmethod
    def vote(track: SessionTrack, user: User):
        track.votes.remove(user) if user in track.votes.all() else track.votes.add(user)
        track.votes_count = track.votes.count()
        track.save()

    def play_next(self) -> SessionTrack:
        if self.play_session.mode == self.play_session.Modes.repeat:
            return self.play_track(self.current_track)
        return self.play_track(self.next_track)

    def play_previous(self) -> SessionTrack:
        if self.play_session.mode == self.play_session.Modes.repeat:
            return self.play_track(self.current_track)
        return self.play_track(self.previous_track)

    @lookup_track
    def play_track(self, track: [int, SessionTrack]) -> SessionTrack:
        first_track = self.current_track
        next_track = self.next_track
        last_track = self.previous_track

        first_track.order, next_track.order = next_track.order, first_track.order
        first_track.order, last_track.order = last_track.order, first_track.order

        first_track.state = SessionTrack.States.stopped
        next_track.state = SessionTrack.States.playing

        first_track.save()
        next_track.save()
        last_track.save()


        # first_track = self.current_track
        # next_track = self.next_track
        # last_track = self.previous_track
        #
        # if track == last_track:
        #     first_track, last_track = last_track, first_track
        #
        # first_track.order, next_track.order = next_track.order, first_track.order
        # first_track.order, last_track.order = last_track.order, first_track.order
        #
        # first_track.state = SessionTrack.States.stopped
        # next_track.state = SessionTrack.States.playing
        # first_track.save()
        # next_track.save()
        # last_track.save()
        #
        # for i, t in enumerate(self.play_session.track_queue.all()):
        #     t.order = i
        #     t.save()
        #
        # current_track = self.play_session.track_queue.first()
        # if current_track.votes.count():
        #     current_track.votes.clear()
        #     current_track.votes_count = current_track.votes.count()
        #     current_track.save()
        #     n, p = self.next_track, self.previous_track
        #     n.order, p.order = p.order, n.order
        #     n.save()
        #     p.save()
        # print(self.play_session.track_queue.all())
        return track

    @property
    def previous_track(self) -> SessionTrack:
        return self.play_session.track_queue.last()

    @property
    def current_track(self) -> SessionTrack:
        return self.play_session.track_queue.order_by('order').first()

    @property
    def next_track(self) -> SessionTrack:
        if self.play_session.track_queue.count() >= 2:
            return self.play_session.track_queue.all()[1]
        else:
            return self.current_track

    def shuffle(self):
        tracks = list(self.play_session.playlist.tracks.all())
        self.play_session.track_queue.all().delete()
        for i in range(len(tracks)):
            random_track = random.choice(tracks)
            session_track = SessionTrack.objects.create(track=tracks.pop(tracks.index(random_track)), order=i)
            self.play_session.track_queue.add(session_track)

    def pause_track(self):
        self.current_track.state = SessionTrack.States.paused
        self.current_track.save()

    def resume_track(self):
        self.current_track.state = SessionTrack.States.playing
        self.current_track.save()

    def stop_track(self):
        self.current_track.state = SessionTrack.States.stopped
        self.current_track.save()
