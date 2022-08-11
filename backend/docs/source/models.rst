Models
=========================================

User
____________________
.. py:currentmodule:: music_room.models
.. autoclass:: User
   :members: playlists
   :undoc-members:

Track
____________________
.. py:currentmodule:: music_room.models
.. autoclass:: Track
   :members: name, files

Track File
____________________
.. py:currentmodule:: music_room.models
.. autoclass:: TrackFile
   :members: file, extension, Extensions, duration, track
   :undoc-members:

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
   :members: name, access_type, AccessTypes, type, Types, author, access_users, tracks
   :undoc-members:

Playlist Access
____________________
.. autoclass:: PlaylistAccess
   :members: user, playlist
