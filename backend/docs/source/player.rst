Player
=================

.. title:: Player websocket

Where send data?
++++++++++++++++
.. note::
   **/ws/player/<user_id>/**

Events list
++++++++++++++++

.. note::
    .. include:: events_note.txt

.. autoclass:: ws.player.EventsList
  :inherited-members:
  :undoc-members:

.. note::
    .. include:: events_detail_note.txt

Create Session
"""""""""""""""""""
.. autoattribute:: ws.player.EventsList.create_session
   :noindex:

.. seealso::
   :obj:`.Examples.create_session_request`
   :obj:`.Examples.session_changed_response`
.. autoclass:: ws.player.PlayerConsumer.CreateSession
   :inherited-members:

Remove Session
"""""""""""""""""""
.. autoattribute:: ws.player.EventsList.remove_session
   :noindex:

.. seealso::
   :obj:`.Examples.remove_session_request`
.. autoclass:: ws.player.PlayerConsumer.RemoveSession
   :inherited-members:

Play Track
"""""""""""""""""""
.. autoattribute:: ws.player.EventsList.play_track
   :noindex:

.. seealso::
   :obj:`.Examples.play_track_request`
   :obj:`.Examples.session_changed_response`
.. autoclass:: ws.player.PlayerConsumer.PlayTrack
   :inherited-members:

Play Next Track
"""""""""""""""""""
.. autoattribute:: ws.player.EventsList.play_next_track
   :noindex:

.. seealso::
   :obj:`.Examples.play_next_track_request`
   :obj:`.Examples.session_changed_response`
.. autoclass:: ws.player.PlayerConsumer.PlayNextTrack
   :inherited-members:

Play Previous Track
"""""""""""""""""""
.. autoattribute:: ws.player.EventsList.play_previous_track
   :noindex:

.. seealso::
   :obj:`.Examples.play_previous_track_request`
   :obj:`.Examples.session_changed_response`
.. autoclass:: ws.player.PlayerConsumer.PlayPreviousTrack
   :inherited-members:

Shuffle
"""""""""""""""""""
.. autoattribute:: ws.player.EventsList.shuffle
   :noindex:

.. seealso::
   :obj:`.Examples.shuffle_request`
   :obj:`.Examples.session_changed_response`
.. autoclass:: ws.player.PlayerConsumer.Shuffle
   :inherited-members:

Pause Track
"""""""""""""""""""
.. autoattribute:: ws.player.EventsList.pause_track
   :noindex:

.. seealso::
   :obj:`.Examples.pause_track_request`
   :obj:`.Examples.session_changed_response`
.. autoclass:: ws.player.PlayerConsumer.PauseTrack
   :inherited-members:

Resume Track
"""""""""""""""""""
.. autoattribute:: ws.player.EventsList.resume_track
   :noindex:

.. seealso::
   :obj:`.Examples.resume_track_request`
   :obj:`.Examples.session_changed_response`
.. autoclass:: ws.player.PlayerConsumer.ResumeTrack
   :inherited-members:

Stop Track
"""""""""""""""""""
.. autoattribute:: ws.player.EventsList.stop_track
   :noindex:

.. seealso::
   :obj:`.Examples.stop_track_request`
   :obj:`.Examples.session_changed_response`
.. autoclass:: ws.player.PlayerConsumer.StopTrack
   :inherited-members:

Sync Track
"""""""""""""""""""
.. autoattribute:: ws.player.EventsList.sync_track
   :noindex:

.. seealso::
   :obj:`.Examples.sync_track_request`
.. autoclass:: ws.player.PlayerConsumer.SyncTrack
   :inherited-members:

Whats data send to socket?
++++++++++++++++++++++++++++

Modify Track
""""""""""""""""""""

.. autoclass:: ws.player.signatures.RequestPayload.ModifyTrack
   :inherited-members:
.. autoclass:: ws.player.signatures.RequestPayloadWrap.PlayTrack
   :inherited-members:
.. autoclass:: ws.player.signatures.RequestPayloadWrap.PlayNextTrack
   :inherited-members:
.. autoclass:: ws.player.signatures.RequestPayloadWrap.PlayPreviousTrack
   :inherited-members:
.. autoclass:: ws.player.signatures.RequestPayloadWrap.Shuffle
   :inherited-members:
.. autoclass:: ws.player.signatures.RequestPayloadWrap.PauseTrack
   :inherited-members:
.. autoclass:: ws.player.signatures.RequestPayloadWrap.ResumeTrack
   :inherited-members:
.. autoclass:: ws.player.signatures.RequestPayloadWrap.StopTrack
   :inherited-members:

Create Session
"""""""""""""""""""

.. autoclass:: ws.player.signatures.RequestPayloadWrap.CreateSession
   :inherited-members:
.. autoclass:: ws.player.signatures.RequestPayload.CreateSession
   :inherited-members:

Sync Track
"""""""""""""""""""

.. autoclass:: ws.player.signatures.RequestPayloadWrap.SyncTrack
   :inherited-members:
.. autoclass:: ws.player.signatures.RequestPayload.SyncTrack
   :inherited-members:

Whats data receive from socket?
++++++++++++++++++++++++++++++++

Play Track
""""""""""""""""""""

.. autoclass:: ws.player.signatures.ResponsePayload.PlayTrack
   :inherited-members:

Player Session
"""""""""""""""""""

.. autoclass:: ws.player.signatures.ResponsePayload.PlayerSession
   :inherited-members:

Examples
+++++++++++++++++++++++++++

.. module:: ws.player
.. autoclass:: Examples

Requests
""""""""""""""""""""

.. autoattribute:: Examples.create_session_request
.. autoattribute:: Examples.remove_session_request
.. autoattribute:: Examples.play_track_request
.. autoattribute:: Examples.play_next_track_request
.. autoattribute:: Examples.play_previous_track_request
.. autoattribute:: Examples.shuffle_request
.. autoattribute:: Examples.pause_track_request
.. autoattribute:: Examples.resume_track_request
.. autoattribute:: Examples.stop_track_request
.. autoattribute:: Examples.sync_track_request

Response
""""""""""""""""""""

.. autoattribute:: Examples.session_response
.. autoattribute:: Examples.session_changed_response



