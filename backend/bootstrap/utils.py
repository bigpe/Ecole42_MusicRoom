import functools
import random
import time
import datetime
from typing import Callable

from django.db.models import BigAutoField, Model, TextField, ForeignKey, ManyToManyField, DateField, DateTimeField, \
    IntegerField, PositiveIntegerField, SmallIntegerField, BigIntegerField, PositiveSmallIntegerField, \
    PositiveBigIntegerField, TimeField, SmallAutoField, AutoField, EmailField, JSONField, ImageField, FileField, \
    IPAddressField, GenericIPAddressField, DecimalField, FloatField, BooleanField, NullBooleanField, CharField, \
    UUIDField, FilePathField, URLField, SlugField
import mimesis
from pytz import timezone
from pathlib import Path

from django.core.files.base import ContentFile
from django.db import models

from django.conf import settings

BASE_DIR = Path(__file__).resolve().parent

IMAGE_PLACEHOLDER = ContentFile(open(BASE_DIR.joinpath('placeholder.png'), 'rb').read(), name='placeholder.png')
FILE_PLACEHOLDER = ContentFile(open(BASE_DIR.joinpath('placeholder.pdf'), 'rb').read(), name='placeholder.pdf')
VIDEO_PLACEHOLDER = ContentFile(open(BASE_DIR.joinpath('placeholder.mp4'), 'rb').read(), name='placeholder.mp4')
AUDIO_PLACEHOLDER = ContentFile(open(BASE_DIR.joinpath('placeholder.mp3'), 'rb').read(), name='placeholder.mp3')
DOCX_PLACEHOLDER = ContentFile(open(BASE_DIR.joinpath('placeholder.docx'), 'rb').read(), name='placeholder.docx')
XLSX_PLACEHOLDER = ContentFile(open(BASE_DIR.joinpath('placeholder.xlsx'), 'rb').read(), name='placeholder.xlsx')


def rgetattr(obj, attr, *args):
    def _getattr(obj, attr):
        return getattr(obj, attr, *args)

    return functools.reduce(_getattr, [obj] + attr.split('.'))


class BootstrapGeneric:
    bootstrap_count = 10
    bootstrap_date_start = '2010-01-01'
    bootstrap_date_end = '2021-05-01'
    bootstrap_time_start = '12:00'
    bootstrap_time_end = '15:00'
    after_bootstrap = None

    def __init__(self, model,
                 bootstrap_logs=True,
                 bootstrap_logs_models=True,
                 bootstrap_logs_objects=True,
                 bootstrap_logs_fields=False,
                 bootstrap_prune=False,
                 bootstrap_field_type_rules=None,
                 bootstrap_field_type_rules_after_save=None,
                 bootstrap_language='en',
                 skip_prune=False
                 ):
        self.__generator = mimesis
        self.bootstrap_language = bootstrap_language
        if bootstrap_prune and not skip_prune:
            message = prune_model(model)
            if bootstrap_logs and bootstrap_logs_models:
                print(message)

        field_type_rules = {
            AutoField: {'skip': ['id']},
            SmallAutoField: {'skip': ['id']},
            BigAutoField: {'skip': ['id']},
            CharField: {'function': self.bootstrap_string},
            TextField: {'function': self.bootstrap_string},
            ForeignKey: {'function': self.bootstrap_foreign_key},
            DateField: {'function': self.bootstrap_date},
            DateTimeField: {'function': self.bootstrap_date_time},
            TimeField: {'function': self.bootstrap_time},
            IntegerField: {'function': self.bootstrap_integer},
            SmallIntegerField: {'function': self.bootstrap_integer},
            BigIntegerField: {'function': self.bootstrap_integer},
            PositiveIntegerField: {'function': self.bootstrap_positive_integer},
            PositiveSmallIntegerField: {'function': self.bootstrap_positive_integer},
            PositiveBigIntegerField: {'function': self.bootstrap_positive_integer},
            DecimalField: {'function': self.bootstrap_decimal},
            FloatField: {'function': self.bootstrap_float},
            EmailField: {'function': self.bootstrap_email},
            JSONField: {'function': self.bootstrap_json},
            IPAddressField: {'function': self.bootstrap_ip},
            GenericIPAddressField: {'function': self.bootstrap_ip},
            BooleanField: {'function': self.bootstrap_boolean},
            NullBooleanField: {'function': self.bootstrap_null_boolean},
            UUIDField: {'function': self.bootstrap_uuid},
            FilePathField: {'function': self.bootstrap_file_path},
            URLField: {'function': self.bootstrap_url},
            SlugField: {'function': self.bootstrap_slug},
        }
        if bootstrap_field_type_rules:
            field_type_rules.update(bootstrap_field_type_rules)
        field_type_rules = self.resolve_bootstrap_fields(field_type_rules)

        field_type_rules_after_save = {
            ManyToManyField: {'function': self.bootstrap_many_to_many},
            ImageField: {'function': self.bootstrap_image},
            FileField: {'function': self.bootstrap_file},
        }
        if bootstrap_field_type_rules_after_save:
            field_type_rules_after_save.update(bootstrap_field_type_rules_after_save)
        field_type_rules_after_save = self.resolve_bootstrap_fields(field_type_rules_after_save)

        for _ in range(self.bootstrap_count):
            obj: Model = model._meta.model()
            fields = self.get_fields(obj)
            after_save = []
            logs = []
            for field in fields:
                field_type = type(field)
                if field_type in field_type_rules:
                    if 'skip' in field_type_rules[field_type]:
                        # Check type + name for skip
                        if self.get_field_name(field) in field_type_rules[field_type]['skip']:
                            logs.append(f'\t\tField: {self.get_field_name(field)} - Skipped')
                            continue
                    if 'function' in field_type_rules[field_type]:
                        # Rewrite origin object after call bootstrap function
                        if 'external' in field_type_rules[field_type]:  # If external, pass bootstrap object
                            obj = field_type_rules[field_type].get('function', lambda b, o, f: ...)(self, obj, field)
                        else:
                            obj = field_type_rules[field_type].get('function', lambda o, f: ...)(obj, field)
                        if field.unique:
                            duplicate = model.objects.filter(
                                **{self.get_field_name(field): getattr(obj, self.get_field_name(field))}
                            ).all()
                            if duplicate:  # Re-roll if duplicate
                                # TODO DRY and Recursive Re-roll
                                if 'external' in field_type_rules[field_type]:
                                    obj = field_type_rules[field_type].get(
                                        'function', lambda b, o, f: ...)(self, obj, field)
                                else:
                                    obj = field_type_rules[field_type].get('function', lambda o, f: ...)(obj, field)
                        field_value = getattr(obj, self.get_field_name(field))
                        logs.append(f'\t\tField: {self.get_field_name(field)} - Generated ({field_value})')
                if field_type in field_type_rules_after_save:
                    if 'function' in field_type_rules_after_save[field_type]:
                        after_save.append({
                            'callback': lambda f: field_type_rules_after_save[type(f)]['function'](obj, f),
                            'field': field
                        })
                        if 'external' in field_type_rules_after_save[field_type]:  # If external, pass bootstrap object
                            after_save[-1].update({
                                'callback': lambda f: field_type_rules_after_save[type(f)]['function'](self, obj, f),
                            })
            obj.save()
            if bootstrap_logs and bootstrap_logs_objects:
                print(f'\tObject: {obj} #{obj.id} - Saved')
            for callback in after_save:
                callback['callback'](callback['field'])
                field_value = getattr(obj, self.get_field_name(callback['field']))
                logs.append(f"\t\tField: {self.get_field_name(callback['field'])} - Generated ({field_value})")
            if bootstrap_logs and bootstrap_logs_fields:
                [print(log) for log in logs]

            if self.after_bootstrap:
                self.after_bootstrap(obj)

    @staticmethod
    def get_field_name(field):
        field_name = field.attname
        return field_name

    @staticmethod
    def get_fields(model: Model):
        fields = list(model._meta.fields)
        fields.extend(list(model._meta.many_to_many))
        return fields

    @staticmethod
    def resolve_field_generator(field_generator, addition_type_rules=None):
        type_rules = {
            Callable: lambda f_g: f_g(),
            list: lambda f_g: random.choice(f_g),
            set: lambda f_g: random.choice(f_g),
        }

        if addition_type_rules:
            type_rules.update(addition_type_rules)

        field_generator_type = type(field_generator)

        for type_rule in type_rules:  # At first check field type instance
            if isinstance(field_generator, type_rule):
                field_value = type_rules.get(type_rule, lambda f_g: ...)(field_generator)
                return field_value

        if field_generator_type in type_rules:  # Rewrite if direct type is exist
            field_value = type_rules.get(field_generator_type, lambda f_g: ...)(field_generator)
        else:
            field_value = field_generator

        return field_value

    @staticmethod
    def resolve_bootstrap_fields(fields_rules):
        fields_to_append = []
        fields_to_pop = []
        for rule in fields_rules:
            if isinstance(rule, str):
                r: list = rule.split('.')
                from importlib import __import__
                module_name = r.pop(0)
                module = __import__(module_name)
                field = rgetattr(module, '.'.join(r))
                fields_rules[rule].update({'external': True})
                fields_to_append.append({field: fields_rules[rule]})
                fields_to_pop.append(rule)
        if fields_to_append:
            for f_a in fields_to_append:
                fields_rules.update(f_a)
        if fields_to_pop:
            fields_rules.pop(*fields_to_pop)
        return fields_rules

    def bootstrap_field_base(self, obj, field, default):
        field_generator, field_name, field_value = self.get_generator_name_and_value(field)

        if field_generator is None:
            field_value = self.resolve_field_generator(default)
        return obj, field_generator, field_name, field_value

    def bootstrap_field(self, obj, field, default):
        obj, field_generator, field_name, field_value = self.bootstrap_field_base(obj, field, default)
        setattr(obj, field_name, field_value)
        return obj

    def bootstrap_field_after_save(self, obj, field, default, callback=None):
        obj, field_generator, field_name, field_value = self.bootstrap_field_base(obj, field, default)
        if callback:
            callback(obj, field_name, field_value)
        return obj

    def get_generator_name_and_value(self, field):
        field_generator, field_name = self.get_field_generator(field), self.get_field_name(field)
        field_value = self.resolve_field_generator(field_generator)
        return field_generator, field_name, field_value

    def get_field_generator(self, field):
        field_name = self.get_field_name(field)
        has_field_generator = hasattr(self, field_name)
        field_generator = getattr(self, field_name) if has_field_generator else None
        if not field_generator:
            field_choices = getattr(field, 'choices', [])
            if field_choices:
                field_generator = [choice[0] for choice in field_choices]
        return field_generator

    def bootstrap_string(self, obj, field):
        field_generator, field_name, field_value = self.get_generator_name_and_value(field)

        if field_generator is None:
            field_value = self.__generator.Text(self.bootstrap_language).quote()
        if hasattr(field, 'max_length'):
            setattr(obj, field_name, field_value[:field.max_length])
        else:
            setattr(obj, field_name, field_value)
        return obj

    def bootstrap_foreign_key(self, obj, field):
        field.attname = self.get_field_name(field).rsplit('_id', 1)[0]
        field_name = field.attname
        field_generator = self.get_field_generator(field)
        field.attname = field.attname + '_id'
        field_value = self.resolve_field_generator(field_generator)

        if field_generator is None:
            field_value = get_random_model(field.related_model)
        setattr(obj, field_name, field_value)
        return obj

    def bootstrap_many_to_many(self, obj, field):
        field_generator, field_name, field_value = self.get_generator_name_and_value(field)
        random_model_ids = {}

        if isinstance(field_generator, Model):
            random_model_ids = get_random_models_ids(field_generator)
        if field_generator is None:
            field_value = field.related_model
            random_model_ids = get_random_models_ids(field_value)
        add_many_to_model(obj, field_name, field_value, random_model_ids)

    def bootstrap_image(self, obj, field):
        return self.bootstrap_field_after_save(obj, field, default=IMAGE_PLACEHOLDER, callback=add_file_to_model)

    def bootstrap_file(self, obj, field):
        return self.bootstrap_field_after_save(obj, field, default=FILE_PLACEHOLDER, callback=add_file_to_model)

    def bootstrap_date(self, obj, field):
        return self.bootstrap_field(
            obj, field, lambda: get_random_date(self.bootstrap_date_start, self.bootstrap_date_end, only_date=True))

    def bootstrap_date_time(self, obj, field):
        return self.bootstrap_field(
            obj, field, lambda: get_random_date(f'{self.bootstrap_date_start} {self.bootstrap_time_start}',
                                                f'{self.bootstrap_date_end} {self.bootstrap_time_end}'))

    def bootstrap_time(self, obj, field):
        return self.bootstrap_field(obj, field, self.__generator.Datetime().time)

    def bootstrap_integer(self, obj, field):
        return self.bootstrap_field(obj, field, lambda: self.__generator.Numeric().integer_number(-1000000, 1000000))

    def bootstrap_positive_integer(self, obj, field):
        return self.bootstrap_field(obj, field, lambda: self.__generator.Numeric().integer_number(0, 1000000))

    def bootstrap_decimal(self, obj, field):
        return self.bootstrap_field(obj, field, lambda: str(round(random.uniform(0, 5), field.decimal_places)))

    def bootstrap_float(self, obj, field):
        return self.bootstrap_field(obj, field, lambda: self.__generator.Numeric().float_number(0, 1000000))

    def bootstrap_email(self, obj, field):
        return self.bootstrap_field(obj, field, self.__generator.Person(self.bootstrap_language).email)

    def bootstrap_json(self, obj, field):
        person = self.__generator.Person(self.bootstrap_language)
        text = self.__generator.Text(self.bootstrap_language)
        default = {
            "person": person.full_name(),
            "gender": person.gender(),
            "age": person.age(),
            "email": person.email(),
            "description": text.quote(),
        }
        return self.bootstrap_field(obj, field, default)

    def bootstrap_ip(self, obj, field):
        return self.bootstrap_field(obj, field, self.__generator.Internet().ip_v4)

    def bootstrap_boolean(self, obj, field):
        return self.bootstrap_field(obj, field, self.__generator.Development().boolean)

    def bootstrap_null_boolean(self, obj, field):
        return self.bootstrap_field(
            obj, field, lambda: self.__generator.Choice()([self.__generator.Development().boolean(), None]))

    def bootstrap_uuid(self, obj, field):
        return self.bootstrap_field(obj, field, self.__generator.Cryptographic().uuid)

    def bootstrap_file_path(self, obj, field):
        return self.bootstrap_field(
            obj, field, lambda: self.__generator.Choice()(list(Path(field.path).glob(getattr(field, 'match', '')))))

    def bootstrap_url(self, obj, field):
        return self.bootstrap_field(obj, field, self.__generator.Internet().url)

    def bootstrap_slug(self, obj, field):
        return self.bootstrap_field(obj, field, self.__generator.Internet().slug)


class BootstrapMixin:
    class Bootstrap(BootstrapGeneric):
        pass


def str_time_prop(start, end, time_format, prop):
    stime = time.mktime(time.strptime(start, time_format))
    etime = time.mktime(time.strptime(end, time_format))

    ptime = stime + prop * (etime - stime)

    return time.strftime(time_format, time.localtime(ptime))


def get_random_date(start, end, only_date=False):
    parse_format = '%Y-%m-%d' if only_date else '%Y-%m-%d %H:%M'
    return datetime.datetime.strptime(
        str_time_prop(start, end, parse_format, random.random()), parse_format).replace(tzinfo=timezone('UTC'))


def get_random_time(start, end):
    parse_format = '%H:%M'
    return datetime.datetime.strptime(
        str_time_prop(start, end, parse_format, random.random()), parse_format).replace(tzinfo=timezone('UTC'))


def get_random_models_ids(model: models):
    if model.objects.all().count():
        return {random.choice(model.objects.all()).id for _ in range(random.randint(1, model.objects.all().count()))}
    return {}


def get_random_model(model: models):
    try:
        return random.choice(model.objects.all())
    except IndexError:
        return None


def add_many_to_model(model: models, to, model_to, ids):
    for Id in ids:
        getattr(model, to).add(model_to.objects.get(id=Id))


def add_file_to_model(model: models, field_name, file_content):
    file = getattr(model, field_name)
    file_name = getattr(file_content, 'name', 'file.test')
    file.save(f'{file_name}', file_content)


def true_or_false(true_value=None, false_value=None):
    res = bool(random.randint(0, 1))
    if true_value or false_value:
        res = true_value if true_value else false_value
    return res


def prune_model(model: models):
    try:
        model.objects.all().delete()
        return f'Model: {model._meta.object_name} - Prune complete'
    except Exception as err:
        return f'Model: {model._meta.object_name} - Prune failed ({err})'


def bootstrap_apps(apps_list):
    models_list = []
    for app in apps_list:
        for model in apps_list[app]:
            if apps_list[app][model]._meta.proxy:  # Skip proxy models
                continue
            models_list.append(apps_list[app][model])
    bootstrap_models(models_list)


def bootstrap_models(models_list):
    models_skip = set()
    bootstrap_logs = getattr(settings, 'BOOTSTRAP_LOGS', True)
    bootstrap_logs_models = getattr(settings, 'BOOTSTRAP_LOGS_MODELS', True)
    args = [
        bootstrap_logs,
        bootstrap_logs_models,
        getattr(settings, 'BOOTSTRAP_LOGS_OBJECTS', False),
        getattr(settings, 'BOOTSTRAP_LOGS_FIELDS', False),
        getattr(settings, 'BOOTSTRAP_PRUNE', False),
        getattr(settings, 'BOOTSTRAP_FIELD_TYPE_RULES', None),
        getattr(settings, 'BOOTSTRAP_FIELD_TYPE_RULES_AFTER_SAVE', None),
        getattr(settings, 'BOOTSTRAP_LANGUAGE', 'en'),
    ]
    for model in models_list:
        skip_prune = False
        if model.__name__.lower() in models_skip:
            continue
        if hasattr(model, 'Bootstrap'):
            fields = BootstrapGeneric.get_fields(model)
            for field in fields:  # Check all field for first bootstrap related models
                if (isinstance(field, ForeignKey) or isinstance(field, ManyToManyField)) and hasattr(
                        field.related_model, 'Bootstrap') and field.related_model.__name__.lower() not in models_skip:
                    models_skip.add(field.related_model.__name__.lower())  # If create related, skip bootstrap it
                    skip_prune = True
                    try:
                        field.related_model.Bootstrap(field.related_model, *args)
                        if bootstrap_logs and bootstrap_logs_models:
                            print(f'Model: {field.related_model.__name__} - Bootstrap complete '
                                  f'({field.related_model.Bootstrap.bootstrap_count})')
                    except Exception as err:
                        if bootstrap_logs and bootstrap_logs_models:
                            print(f'Model: {field.related_model.__name__} - Bootstrap failed ({err})')
            models_skip.add(model.__name__.lower())  # Prevent recall bootstrap
            try:
                model.Bootstrap(model, *args, skip_prune=skip_prune)
            except Exception as err:
                if bootstrap_logs and bootstrap_logs_models:
                    print(f'Model: {model.__name__} - Bootstrap failed ({err})')
            if bootstrap_logs and bootstrap_logs_models:
                print(f'Model: {model.__name__} - Bootstrap complete ({model.Bootstrap.bootstrap_count})')
