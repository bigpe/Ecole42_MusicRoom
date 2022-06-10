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

session: PlaySession = PlaySession.objects.first()

#
session.shuffle()
print(session.track_queue.all())
# session.previous_track.vote(User.objects.first())
track = session.previous_track
session.play_next()
session.play_previous()

# print(session.track_queue.all().values('votes'))

