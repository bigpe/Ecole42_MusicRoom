Models
=========================================

Track
____________________
.. py:currentmodule:: music_room.models
.. autoclass:: Track
   :members: name, file, duration

Playlist Track
____________________
.. autoclass:: PlaylistTrack
   :members: track, order

Session Track
____________________
.. autoclass:: SessionTrack
   :members: state, States, track, votes, votes_count, progress, order
   :undoc-members:

Player Session
____________________
.. autoclass:: PlayerSession
   :members: playlist, track_queue, mode, Modes, author
   :undoc-members:

Playlist
____________________
.. autoclass:: Playlist
   :members: name, type, Types, author
   :undoc-members:
