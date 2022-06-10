from django.core.management.base import BaseCommand, CommandError

from bootstrap.utils import bootstrap_apps, bootstrap_models


class Command(BaseCommand):
    help = 'Bootstrap apps models with Bootstrap class (instance of BootstrapGeneric)'
    requires_migrations_checks = True

    def add_arguments(self, parser):
        parser.add_argument('args', metavar='app_label', nargs='*', help='Application label for bootstrap.')
        parser.add_argument('-a', '--all', action='store_true', help='Bootstrap all models from all apps.')

    def handle(self, *app_labels, **options):
        from django.apps import apps
        from django.conf import settings
        if not getattr(settings, 'BOOTSTRAP_ENABLED', False):
            raise CommandError("Bootstrap disabled. Set BOOTSTRAP_ENABLED=True in settings.")
        try:
            [apps.get_app_config(f'{app_label}.'.split('.')[0]) for app_label in app_labels]
        except (LookupError, ImportError) as e:
            raise CommandError("%s. Are you sure your INSTALLED_APPS setting is correct?" % e)
        apps = apps.all_models
        models_to_bootstrap = set()
        for app_label in app_labels:
            if '.' in app_label:
                model_name = app_label.split('.')[-1]
                app_label = app_label.split('.')[0]
                models_to_bootstrap.add(apps[app_label][model_name])
        apps_to_bootstrap = apps if options['all'] else {app_label: apps[app_label] for app_label in app_labels}
        bootstrap_apps(apps_to_bootstrap)
        bootstrap_models(models_to_bootstrap)
