# Generated by Django 3.2.15 on 2022-10-24 14:51

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('music_room', '0021_remove_event_playlist'),
    ]

    operations = [
        migrations.AlterField(
            model_name='playlist',
            name='name',
            field=models.CharField(default='<function uuid4 at 0x10faa7b50>', max_length=150),
        ),
    ]
