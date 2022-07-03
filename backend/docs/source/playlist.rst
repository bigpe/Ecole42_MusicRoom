Playlist
=================

.. title:: Playlist websocket

Where send data?
++++++++++++++++

All playlists
"""""""""""""""""""""
:obj:`.rename_playlist` :obj:`.add_playlist` :obj:`.remove_playlist`


.. note::
   **/ws/playlist/<user_id>/**

Current showed playlist
"""""""""""""""""""""""""
:obj:`.add_track` :obj:`.remove_track`

.. note::
   **/ws/playlist/<int:playlist_id>/<user_id>/**

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

Invite to Playlist
"""""""""""""""""""
.. autoattribute:: ws.playlist.EventsList.invite_to_playlist
   :noindex:

.. seealso::
   :obj:`.Examples.invite_to_playlist_request`
.. autoclass:: ws.playlist.PlaylistRetrieveConsumer.InviteToPlaylist
   :inherited-members:

Revoke from Playlist
"""""""""""""""""""
.. autoattribute:: ws.playlist.EventsList.revoke_from_playlist
   :noindex:

.. seealso::
   :obj:`.Examples.revoke_from_playlist_request`
.. autoclass:: ws.playlist.PlaylistRetrieveConsumer.RevokeFromPlaylist
   :inherited-members:

Whats data send to socket?
++++++++++++++++++++++++++++

Modify Playlist Tracks
""""""""""""""""""""""""""

.. autoclass:: ws.playlist.signatures.RequestPayload.ModifyPlaylistTracks
   :inherited-members:
.. autoclass:: ws.playlist.signatures.RequestPayloadWrap.AddTrack
   :inherited-members:
   :noindex:
.. autoclass:: ws.playlist.signatures.RequestPayloadWrap.RemoveTrack
   :inherited-members:
   :noindex:

Modify Playlist
""""""""""""""""""""""""""

.. autoclass:: ws.playlist.signatures.RequestPayload.ModifyPlaylist
   :inherited-members:
.. autoclass:: ws.playlist.signatures.RequestPayloadWrap.RenamePlaylist
   :inherited-members:
   :noindex:
.. autoclass:: ws.playlist.signatures.RequestPayloadWrap.RemovePlaylist
   :inherited-members:
   :noindex:

Modify Playlists
""""""""""""""""""""""""""

.. autoclass:: ws.playlist.signatures.RequestPayload.ModifyPlaylists
   :inherited-members:
.. autoclass:: ws.playlist.signatures.RequestPayloadWrap.AddPlaylist
   :inherited-members:
   :noindex:

Modify Playlist Access
""""""""""""""""""""""""""

.. autoclass:: ws.playlist.signatures.RequestPayload.ModifyPlaylistAccess
   :inherited-members:
.. autoclass:: ws.playlist.signatures.RequestPayloadWrap.InviteToPlaylist
   :inherited-members:
   :noindex:
.. autoclass:: ws.playlist.signatures.RequestPayloadWrap.RevokeFromPlaylist
   :inherited-members:
   :noindex:

Whats data receive from socket?
+++++++++++++++++++++++++++++++++

Playlist
""""""""""""""""""""

.. autoclass:: ws.playlist.signatures.ResponsePayload.PlaylistChanged
   :inherited-members:

Playlists
""""""""""""""""""""

.. autoclass:: ws.playlist.signatures.ResponsePayload.PlaylistsChanged
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
.. autoattribute:: Examples.invite_to_playlist_request
.. autoattribute:: Examples.revoke_from_playlist_request

Response
""""""""""""""""""""

.. autoattribute:: Examples.playlist_changed_response
.. autoattribute:: Examples.playlists_changed_response
