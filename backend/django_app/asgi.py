"""
ASGI config for d09 project.

It exposes the ASGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/3.2/howto/deployment/asgi/
"""

import os

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'django_app.settings')

import django

django.setup()

from django.core.asgi import get_asgi_application
from channels.routing import ProtocolTypeRouter, URLRouter
from django.urls import re_path

from .middleware import TokenAuthMiddleware

from ws.player import PlayerConsumer
from ws.playlist import PlaylistsConsumer, PlaylistRetrieveConsumer
from ws.event import EventRetrieveConsumer


application = ProtocolTypeRouter({
    "http": get_asgi_application(),
    "websocket": TokenAuthMiddleware(URLRouter([
        re_path(r'^ws/player/', PlayerConsumer.as_asgi()),
        re_path(r'^ws/playlist/(?P<playlist_id>\d+)/', PlaylistRetrieveConsumer.as_asgi()),
        re_path(r'^ws/playlist/', PlaylistsConsumer.as_asgi()),
        re_path(r'^ws/event/(?P<event_id>\d+)/', EventRetrieveConsumer.as_asgi()),
    ])),
})
