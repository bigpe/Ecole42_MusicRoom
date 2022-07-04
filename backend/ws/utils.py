from typing import Callable

from ws.base import Action, BaseConsumer, dot_to_camel, snake_to_camel, BasePayload, camel_to_snake, dot_to_snake, \
    BaseEvent, Message, ResponsePayload


def dict_key_reformat(data: dict, reformat_func: Callable):
    if not data:
        data = {}
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
        if isinstance(self.payload, tuple):
            self.payload = self.payload[0]
        if not self.payload:
            self.payload = {}
        if not self.payload.get(dot_to_camel(self.event), None):
            self.payload = {dot_to_camel(self.event): self.payload}
        return super(ActionRef, self).to_data(to_json, pop_system)

    def to_system_data(self, to_json=False, pop_system=False):
        return self.__str__(to_json=False)


class BaseEventRef(BaseEvent):
    def __call__(self, payload: [dict, BasePayload]) -> [Action, None]:
        if isinstance(payload, BasePayload):
            payload = payload.to_data()
        event = self.event
        return ActionRef(event=event.pop('type'), system=event.pop('system'), payload={self.event_name: payload})


class BaseConsumerRef(BaseConsumer):
    request_type_resolver = {}

    def parse_payload(self, event, payload_type: BasePayload()):
        def parse(f: Callable):
            return self.check_signature(f)

        event['payload'] = dict_key_reformat(event['payload'], camel_to_snake)
        payload = BasePayload(**event['payload'])
        error = False
        event_name = dot_to_snake(event['type'])
        if self.request_type_resolver:
            additional_payload_type = self.request_type_resolver.get(event_name)
            if additional_payload_type:
                payload, error = parse(lambda: additional_payload_type(**payload.to_data()))
                if error:
                    return payload, error
            if payload_type:
                payload, error = parse(lambda: payload_type(**getattr(payload, event_name)))
                if error:
                    return payload, error
        if payload_type:
            payload, error = parse(lambda: payload_type(**payload.to_data()))
        return payload, error

    class Error(BaseEventRef):
        """Show error message"""
        request_payload_type = ResponsePayload.Error

        def action_for_initiator(self, message: Message, payload: request_payload_type):
            return self(payload=ResponsePayload.Error(message=payload.message))
