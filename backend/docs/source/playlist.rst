Playlist
=================

.. title:: Playlist websocket

Where send data?
++++++++++++++++

All playlists
"""""""""""""""""""""
:obj:`.rename_playlist` :obj:`.add_playlist` :obj:`.remove_playlist`


.. note::
   **/ws/playlist/<str:token/user_id>/**

Current showed playlist
"""""""""""""""""""""""""
:obj:`.add_track` :obj:`.remove_track`

.. note::
   **/ws/playlist/<int:playlist_id>/<str:token/user_id>/**

Events list
++++++++++++++++

.. note::
    .. include:: events_note.txt

.. autoclass:: ws.playlist.EventsList
   :inherited-members:
   :undoc-members:

.. note::
    .. include:: events_detail_note.txt

Rename Playlist
"""""""""""""""""""
.. autoattribute:: ws.playlist.EventsList.rename_playlist
   :noindex:

.. seealso::
   :obj:`.Examples.rename_playlist_request`
   :obj:`.Examples.playlists_changed_response`
.. autoclass:: ws.playlist.PlaylistsConsumer.RenamePlaylist
   :inherited-members:

Add Playlist
"""""""""""""""""""
.. autoattribute:: ws.playlist.EventsList.add_playlist
   :noindex:

.. seealso::
   :obj:`.Examples.add_playlist_request`
   :obj:`.Examples.playlists_changed_response`
.. autoclass:: ws.playlist.PlaylistsConsumer.AddPlaylist
   :inherited-members:

Remove Playlist
"""""""""""""""""""
.. autoattribute:: ws.playlist.EventsList.remove_playlist
   :noindex:

.. seealso::
   :obj:`.Examples.remove_playlist_request`
   :obj:`.Examples.playlists_changed_response`
.. autoclass:: ws.playlist.PlaylistsConsumer.RemovePlaylist
   :inherited-members:

Add Track
"""""""""""""""""""
.. autoattribute:: ws.playlist.EventsList.add_track
   :noindex:

.. seealso::
   :obj:`.Examples.add_track_request`
   :obj:`.Examples.playlist_changed_response`
.. autoclass:: ws.playlist.PlaylistRetrieveConsumer.AddTrack
   :inherited-members:

Remove Track
"""""""""""""""""""
.. autoattribute:: ws.playlist.EventsList.remove_track
   :noindex:

.. seealso::
   :obj:`.Examples.remove_track_request`
   :obj:`.Examples.playlist_changed_response`
.. autoclass:: ws.playlist.PlaylistRetrieveConsumer.RemoveTrack
   :inherited-members:

Whats data send to socket?
++++++++++++++++++++++++++++

Modify Playlist Tracks
""""""""""""""""""""""""""

.. autoclass:: ws.playlist.signatures.RequestPayload.ModifyPlaylistTracks
   :inherited-members:

Modify Playlist
""""""""""""""""""""""""""

.. autoclass:: ws.playlist.signatures.RequestPayload.ModifyPlaylist
   :inherited-members:

Modify Playlists
""""""""""""""""""""""""""

.. autoclass:: ws.playlist.signatures.RequestPayload.ModifyPlaylists
   :inherited-members:

Whats data receive from socket?
+++++++++++++++++++++++++++++++++

Playlist
""""""""""""""""""""

.. autoclass:: ws.playlist.signatures.ResponsePayload.Playlist
   :inherited-members:

Playlists
""""""""""""""""""""

.. autoclass:: ws.playlist.signatures.ResponsePayload.Playlists
   :inherited-members:

Examples
+++++++++++++++++++++++++++

.. module:: ws.playlist
.. autoclass:: Examples

Requests
""""""""""""""""""""

.. autoattribute:: Examples.rename_playlist_request
.. autoattribute:: Examples.add_playlist_request
.. autoattribute:: Examples.remove_playlist_request
.. autoattribute:: Examples.add_track_request
.. autoattribute:: Examples.remove_track_request

Response
""""""""""""""""""""

.. autoattribute:: Examples.playlist_changed_response
.. autoattribute:: Examples.playlists_changed_response