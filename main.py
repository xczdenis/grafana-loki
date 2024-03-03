import datetime
import random
import time

template = '{date} | {lvl}  | Camel (active-edo_2171) thread #556 - JmsConsumer[soap-connector-edo_2171] | aggregation                      | 151 - org.apache.camel.camel-core - 2.23.2 | ! aggregation !'
lvls = ('INFO', 'WARNING', 'ERROR', 'CRITICAL')


def add_record():
    with open('karaf-logs/karaf-01(5).log', 'a') as config_file:
        date = datetime.datetime.now().strftime('%Y-%m-%dT%H:%M:%S,%f')[:-3]
        lvl = lvls[random.randint(0, 3)]
        s = template.format(date=date, lvl=lvl)
        config_file.write(s)
        config_file.write('\n')


if __name__ == '__main__':
    while True:
        add_record()
        time.sleep(2)
