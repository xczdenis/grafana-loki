import datetime
import random
import time

components = (
    'qtp1508132334-55303',
    'qtp1508132334',
    'Camel (soap-passive-connector-context) thread #99 - Aggregator',
    'Camel (active-edo_2171) thread #556 - JmsConsumer[soap-connector-edo_2171]'
    'default-workqueue-21',
)
lvls = ('INFO', 'WARN', 'ERROR', 'CRITICAL')
action_types = ('aggregation', 'REQ_IN', 'REQ_OUT', 'RESP_IN', 'RESP_out')
msg1 = """\nAddress: http://yandex/google/ws/esbExchange.1cws
    HttpMethod: POST
    Content-Type: application/soap+xml; action="http://www.1c-esb.ru/connector/universal/system/1.0#esbExchange:PutPackets"
    ExchangeId: ddb603c9-df68-43c0-a70e-b2ff66ab10dc
    ServiceName: esbExchange"""
msg2 = ""
msg3 = """\nAddress: http://yandex/google/ws/esbExchange.1cws
    HttpMethod: POST"""
msg4 = "\nAddress: http://yandex"
messages = (msg1, msg2, msg3, msg4)

template = "{date} | {lvl} | {component} | {action_type_1} | 151 - org.apache.camel.camel-core - 2.23.2 | {action_type_2} {msg}"


def add_record():
    with open('karaf-logs/karaf-01(2).log', 'a') as config_file:
        date = datetime.datetime.now().strftime('%Y-%m-%dT%H:%M:%S,%f')[:-3]
        lvl = lvls[random.randint(0, len(lvls)-1)]
        action_type_1 = action_types[random.randint(0, len(action_types) - 1)]
        action_type_2 = action_types[random.randint(0, len(action_types) - 1)]
        msg = messages[random.randint(0, len(messages) - 1)]
        component = components[random.randint(0, len(components) - 1)]
        s = template.format(date=date, lvl=lvl, component=component, action_type_1=action_type_1, action_type_2=action_type_2, msg=msg)
        config_file.write(s)
        config_file.write('\n')


if __name__ == '__main__':
    while True:
        add_record()
        time.sleep(2)
