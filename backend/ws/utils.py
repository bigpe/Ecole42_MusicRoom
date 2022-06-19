from typing import Callable

from ws.base import Action, BaseConsumer, dot_to_camel, snake_to_camel, BasePayload, camel_to_snake, dot_to_snake


def dict_key_reformat(data: dict, reformat_func: Callable):
    new_dict = {}
    for key, value in data.items():
        if isinstance(value, dict):
            new_dict.update(
                {reformat_func(key): dict_key_reformat(value, reformat_func)}
            )
        else:
            new_dict.update({reformat_func(key): value})
    return new_dict


class ActionRef(Action):
    def to_data(self, to_json=False, pop_system=False):
        self.payload = dict_key_reformat(self.payload, snake_to_camel)
        self.payload = {dot_to_camel(self.event): self.payload}
        return super(ActionRef, self).to_data(to_json, pop_system)


class BaseConsumerRef(BaseConsumer):
    request_type_resolver = {}

    def parse_payload(self, event, payload_type: BasePayload()):
        event['payload'] = dict_key_reformat(event['payload'], camel_to_snake)
        payload = BasePayload(**event['payload'])
        error = False
        if self.request_type_resolver:
            event_name = dot_to_snake(event['type'])
            additional_payload_type = self.request_type_resolver.get(event_name)
            if additional_payload_type:
                payload, error = self.check_signature(lambda: additional_payload_type(**payload.to_data()))
                if error:
                    return payload, error
            payload = payload_type(**getattr(payload, event_name))
        if payload_type:
            payload, error = self.check_signature(lambda: payload_type(**payload.to_data()))
        return payload, error
