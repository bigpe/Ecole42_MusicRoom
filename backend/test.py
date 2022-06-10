import os
import sys

sys.path.insert(0, '../.')
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "django_app.settings")
import django

try:
    django.setup()
except Exception:
    ...

from music_room.models import PlaySession
from django.contrib.auth.models import User

play_session:PlaySession = PlaySession.objects.first()

#
play_session.shuffle()
print(play_session.track_queue.all())
# play_session.previous_track.vote(User.objects.first())
track = play_session.previous_track
play_session.play_next()
play_session.play_previous()

# print(play_session.track_queue.all().values('votes'))

