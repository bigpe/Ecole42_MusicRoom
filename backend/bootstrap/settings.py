import os
from typing import Callable


def load_option_from_env(option: str, default: any, transform: Callable = None):
    return transform(os.environ.get(option, default)) if transform else os.environ.get(option, default)


def numeric_to_bool(numeric_string):
    return bool(int(numeric_string))


def split_by_coma(coma_string):
    return coma_string.split(',')


BOOTSTRAP_ENABLED = load_option_from_env('BOOTSTRAP_ENABLED', False, numeric_to_bool)
BOOTSTRAP_PRUNE = load_option_from_env('BOOTSTRAP_PRUNE', False, numeric_to_bool)
BOOTSTRAP_LOGS = True
BOOTSTRAP_LOGS_MODELS = True
BOOTSTRAP_LOGS_OBJECTS = False
BOOTSTRAP_LOGS_FIELDS = False
BOOTSTRAP_LANGUAGE = 'ru'
SECRET_KEY = load_option_from_env('SECRET_KEY', 'dwad765551237DW#&&&44*adwxa')
DEBUG = load_option_from_env('DEBUG', True)
ALLOWED_HOSTS = load_option_from_env('ALLOWED_HOSTS', '*', split_by_coma)
