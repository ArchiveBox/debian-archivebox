# Generated by Django 2.2 on 2019-05-01 03:27

from django.db import migrations, models
import uuid


class Migration(migrations.Migration):

    initial = True

    dependencies = [
    ]

    operations = [
        migrations.CreateModel(
            name='Snapshot',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('url', models.URLField(unique=True)),
                ('timestamp', models.CharField(default=None, max_length=32, null=True, unique=True)),
                ('title', models.CharField(default=None, max_length=128, null=True)),
                ('tags', models.CharField(default=None, max_length=256, null=True)),
                ('added', models.DateTimeField(auto_now_add=True)),
                ('updated', models.DateTimeField(default=None, null=True)),
            ],
        ),
    ]