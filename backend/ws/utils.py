from hashlib import md5

from channels.generic.websocket import JsonWebsocketConsumer
import traceback
import sys
import re


def safe(f):
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
