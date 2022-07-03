from django.conf import settings
from django.urls import path, re_path
from drf_yasg import openapi
from drf_yasg.generators import OpenAPISchemaGenerator
from drf_yasg.views import get_schema_view
from rest_framework.authentication import BasicAuthentication
from rest_framework_simplejwt.views import TokenRefreshView

from .views import TrackListView, PlaylistListView, PlaylistOwnListView, PlayerSessionRetrieveView, AuthView


class BothHttpAndHttpsSchemaGenerator(OpenAPISchemaGenerator):
    def get_schema(self, request=None, public=False):
        schema = super().get_schema(request, public)
        if 'heroku' in schema.host:
            schema.schemes = ["https"]
        else:
            schema.schemes = ["http", "https"]
        return schema


schema_view = get_schema_view(
    openapi.Info(
        **getattr(settings, 'API_INFO', {}),
        default_version='v1'
    ),
    public=True,
    authentication_classes=(BasicAuthentication,),
    generator_class=BothHttpAndHttpsSchemaGenerator,
)

urlpatterns = [
    re_path(r'^(?P<format>\.json|\.yaml)$', schema_view.without_ui(cache_timeout=0), name='schema'),
    re_path(r'^$', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui'),
    re_path(r'^redoc/$', schema_view.with_ui('redoc', cache_timeout=0), name='schema-redoc'),
    path('track/', TrackListView.as_view()),
    path('playlist/', PlaylistListView.as_view()),
    path('playlist/own/', PlaylistOwnListView.as_view()),
    path('player/session/', PlayerSessionRetrieveView.as_view()),
    path('auth/', AuthView.as_view()),
    path('token/refresh/', TokenRefreshView.as_view()),
]
