import functools
from hashlib import md5
from typing import Callable

from channels.generic.websocket import JsonWebsocketConsumer
import traceback
import sys
import re

from django.contrib.auth import get_user_model
from django.core.cache import cache

User = get_user_model()


def camel_to_snake(name):
    name = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
    return re.sub('([a-z0-9])([A-Z])', r'\1_\2', name).lower()


def user_cache_key(user: User):
    return f'user-{user.id}'


def get_system_cache(user: User):
    return cache.get(user_cache_key(user), {})


def safe(f: Callable) -> Callable:
    @functools.wraps(f)
    def wrapper(self: JsonWebsocketConsumer, *args, **kwargs):
        try:
            return f(self, *args, **kwargs)
        except Exception as err:
            error = f'{err.__class__.__name__}: {str(err)}'
            traceback.print_exception(*sys.exc_info())
            tb = traceback.format_exc()
            lines = re.findall(r'line \d*, ', tb)
            for line in lines:
                tb = tb.replace(line, '')
            tb_hash = md5(tb.encode('utf-8')).hexdigest()
            self.send_json(content={'error': 'Something wrong', 'error_message': error, 'error_hash': tb_hash})

    wrapper.__doc__ = f.__doc__
    return wrapper
