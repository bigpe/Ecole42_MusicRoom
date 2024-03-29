# Generated by Django 4.0.5 on 2022-06-19 09:51

from django.db import migrations, models
import music_room.models


class Migration(migrations.Migration):

    dependencies = [
        ('music_room', '0002_alter_track_name'),
    ]

    operations = [
        migrations.AddField(
            model_name='track',
            name='track_file',
            field=models.FileField(default=1, upload_to='music', validators=[music_room.models.audio_file_validator]),
        ),
        migrations.AddField(
            model_name='track',
            name='track_duration',
            field=models.FloatField(blank=True, null=True),
        ),
    ]
