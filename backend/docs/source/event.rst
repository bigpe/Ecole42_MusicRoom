Event
=================

.. title:: Event websocket

Where send data?
++++++++++++++++

Current showed event
"""""""""""""""""""""""""
:obj:`ws.event.EventsList.add_track` :obj:`ws.event.EventsList.remove_track` :obj:`ws.event.EventsList.invite_to_event` :obj:`ws.event.EventsList.revoke_from_event`

.. note::
   **/ws/event/<int:event_id>/**

Events list
++++++++++++++++

.. note::
    .. include:: events_note.txt

.. autoclass:: ws.event.EventsList
   :inherited-members:
   :undoc-members:

.. note::
    .. include:: events_detail_note.txt

Change Event
"""""""""""""""""""
.. autoattribute:: ws.event.EventsList.change_event
   :noindex:

.. seealso::
   :obj:`.Examples.event_change_event_request`
.. autoclass:: ws.event.EventRetrieveConsumer.ChangeEvent
   :inherited-members:

Add Track
"""""""""""""""""""
.. autoattribute:: ws.event.EventsList.add_track
   :noindex:

.. seealso::
   :obj:`.Examples.event_add_track_request`
   :obj:`.Examples.event_playlist_changed_response`
.. autoclass:: ws.event.EventRetrieveConsumer.AddTrack
   :inherited-members:

Remove Track
"""""""""""""""""""
.. autoattribute:: ws.event.EventsList.remove_track
   :noindex:

.. seealso::
   :obj:`.Examples.event_remove_track_request`
   :obj:`.Examples.event_playlist_changed_response`
.. autoclass:: ws.event.EventRetrieveConsumer.RemoveTrack
   :inherited-members:

Invite to Event
"""""""""""""""""""
.. autoattribute:: ws.event.EventsList.invite_to_event
   :noindex:

.. seealso::
   :obj:`.Examples.event_invite_to_event_request`
.. autoclass:: ws.event.EventRetrieveConsumer.InviteToEvent
   :inherited-members:

Revoke from Event
"""""""""""""""""""""""""
.. autoattribute:: ws.event.EventsList.revoke_from_event
   :noindex:

.. seealso::
   :obj:`.Examples.event_revoke_from_event_request`
.. autoclass:: ws.event.EventRetrieveConsumer.RevokeFromEvent
   :inherited-members:

Change User Access Mode
"""""""""""""""""""""""""
.. autoattribute:: ws.event.EventsList.change_user_access_mode
   :noindex:

.. seealso::
   :obj:`.Examples.event_change_user_access_mode_request`
.. autoclass:: ws.event.EventRetrieveConsumer.ChangeUserAccessMode
   :inherited-members:

Whats data send to socket?
++++++++++++++++++++++++++++

Modify Playlist Tracks
""""""""""""""""""""""""""

.. autoclass:: ws.event.signatures.RequestPayload.ModifyPlaylistTracks
   :inherited-members:
.. autoclass:: ws.event.signatures.RequestPayloadWrap.AddTrack
   :inherited-members:
   :noindex:
.. autoclass:: ws.event.signatures.RequestPayloadWrap.RemoveTrack
   :inherited-members:
   :noindex:

Modify Event
""""""""""""""""""""""""""

.. autoclass:: ws.event.signatures.RequestPayload.ModifyEvent
   :inherited-members:
.. autoclass:: ws.event.signatures.RequestPayloadWrap.ChangeEvent
   :inherited-members:
   :noindex:

Modify Event Access
""""""""""""""""""""""""""

.. autoclass:: ws.event.signatures.RequestPayload.ModifyEventAccess
   :inherited-members:
.. autoclass:: ws.event.signatures.RequestPayloadWrap.InviteToEvent
   :inherited-members:
   :noindex:
.. autoclass:: ws.event.signatures.RequestPayloadWrap.RevokeFromEvent
   :inherited-members:
   :noindex:

Modify Accessed Users
""""""""""""""""""""""""""

.. autoclass:: ws.event.signatures.RequestPayload.ModifyUserAccessMode
   :inherited-members:
.. autoclass:: ws.event.signatures.RequestPayloadWrap.ChangeUserAccessMode
   :inherited-members:
   :noindex:

Whats data receive from socket?
+++++++++++++++++++++++++++++++++

Playlist
""""""""""""""""""""

.. autoclass:: ws.event.signatures.ResponsePayload.PlaylistChanged
   :inherited-members:

Event
""""""""""""""""""""

.. autoclass:: ws.event.signatures.ResponsePayload.EventChanged
   :inherited-members:

Examples
+++++++++++++++++++++++++++

.. module:: ws.event
.. autoclass:: Examples

Requests
""""""""""""""""""""

.. autoattribute:: Examples.event_change_event_request
.. autoattribute:: Examples.event_add_track_request
.. autoattribute:: Examples.event_remove_track_request
.. autoattribute:: Examples.event_invite_to_event_request
.. autoattribute:: Examples.event_revoke_from_event_request
.. autoattribute:: Examples.event_change_user_access_mode_request

Response
""""""""""""""""""""

.. autoattribute:: Examples.event_playlist_changed_response
.. autoattribute:: Examples.event_changed_response
