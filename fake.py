import os
import random
from typing import Literal

msg_template = (
    "| {lvl} | {component} | {action_type_1} | {description} | {action_type_2} {msg}"
)

log_levels = ("CRITICAL", "ERROR", "INFO", "WARN")
components = (
    "qtp1508132334-55303",
    "qtp1508132334",
    "Camel (soap-passive-connector-context) thread #99 - Aggregator",
    "Camel (active-edo_2171) thread #556 - JmsConsumer[soap-connector-edo_2171]"
    "default-workqueue-21",
)
action_types = (
    "revert-no-acknowledge-messages",
    "aggregation",
    "REQ_IN",
    "REQ_OUT",
    "RESP_IN",
    "RESP_out",
)
descriptions = (
    "151 - org.apache.camel.camel-core - 2.23.2",
    "192 - org.apache.cxf.cxf-rt-features-logging - 3.2.7",
    "184 - org.apache.cxf.cxf-core - 3.2.7",
)


def fake_message_for_log_level(log_level: Literal["error", "info", "warn"]):
    messages = []

    for filename in os.listdir("msg_templates"):
        with open(os.path.join("msg_templates", filename), "r") as f:
            content = f.read()

        if filename.startswith(log_level.lower()):
            messages.append(content)

    br = random.choice(("", "\n"))

    return f"{br}{random.choice(messages)}"


def fake_log_level():
    return random.choice(log_levels)


def fake_component():
    return random.choice(components)


def fake_action_type():
    return random.choice(action_types)


def fake_description():
    return random.choice(descriptions)


def fake_log_message():
    log_level = fake_log_level()
    msg = fake_message_for_log_level(log_level)
    return msg_template.format(
        lvl=log_level,
        component=fake_component(),
        action_type_1=fake_action_type(),
        description=fake_description(),
        action_type_2=fake_action_type(),
        msg=msg,
    )
