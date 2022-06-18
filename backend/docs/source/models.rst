Models
=========================================

Track
____________________
.. autoclass:: music_room.models.Track
   :members: name

Playlist Track
____________________
.. autoclass:: music_room.models.PlaylistTrack
   :members: track, order

Session Track
____________________
.. autoclass:: music_room.models.SessionTrack
   :members: state, States, track, votes, votes_count, order
   :undoc-members:

Player Session
____________________
.. autoclass:: music_room.models.PlayerSession
   :members: playlist, track_queue, mode, Modes, author
   :undoc-members:

Playlist
____________________
.. autoclass:: music_room.models.Playlist
   :members: name, type, Types, tracks, author
   :undoc-members: