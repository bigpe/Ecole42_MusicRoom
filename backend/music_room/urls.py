from django.urls import path

from .views import TrackListView, PlaylistListView

urlpatterns = [
    path('track/', TrackListView.as_view()),
    path('playlist/', PlaylistListView.as_view()),
]
