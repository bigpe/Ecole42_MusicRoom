# Generated by Django 3.2.15 on 2022-10-24 14:44

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('music_room', '0020_auto_20221023_2222'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='event',
            name='playlist',
        ),
    ]
