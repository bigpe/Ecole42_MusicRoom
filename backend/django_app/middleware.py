from asgiref.sync import sync_to_async
from django.conf import settings
from django.contrib.auth import get_user_model
from django.contrib.auth.models import AnonymousUser
from rest_framework_simplejwt.backends import TokenBackend
from rest_framework_simplejwt.exceptions import TokenBackendError

User = get_user_model()


class AuthMiddlewareFromPath:
    def __init__(self, inner):
        self.inner = inner

    async def __call__(self, scope, receive, send):
        scope['user'] = AnonymousUser()
        try:
            user_id = scope['path'].split('/')[-2]
            scope['user'] = await sync_to_async(lambda: User.objects.get(id=user_id))()
        except Exception:
            ...
        return await self.inner(scope, receive, send)


class TokenAuthMiddleware:
    def __init__(self, inner):
        self.inner = inner

    async def __call__(self, scope, receive, send):
        headers = dict(scope['headers'])
        scope['user'] = AnonymousUser()
        if b'authorization' in headers:
            try:
                token_name, token_key = headers[b'authorization'].decode().split()
                token = TokenBackend(algorithm='HS256', signing_key=settings.SECRET_KEY).decode(token_key, verify=True)
                if token_name == 'Bearer':
                    scope['user'] = await sync_to_async(lambda: User.objects.get(id=token.get('user_id')))()
            except TokenBackendError:
                scope['user'] = AnonymousUser()
        return await self.inner(scope, receive, send)
