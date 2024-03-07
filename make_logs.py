import logging
import os
import random
import time
from logging.handlers import RotatingFileHandler

from fake import fake_log_message


class CustomFormatter(logging.Formatter):
    def formatTime(self, record, datefmt=None):
        ct = self.converter(record.created)
        if datefmt:
            t = time.strftime(datefmt, ct)
            s = "%s,%03d" % (t, record.msecs)
        else:
            s = time.strftime("%Y-%m-%dT%H:%M:%S", ct)
            s = "%s,%03d" % (s, record.msecs)
        return s


def setup_logging(log_path, max_size_bytes, backup_count):
    if not os.path.isdir(os.path.dirname(log_path)):
        os.makedirs(os.path.dirname(log_path), exist_ok=True)

    logger = logging.getLogger("MyLogger")
    logger.setLevel(logging.DEBUG)

    handler = RotatingFileHandler(
        log_path, maxBytes=max_size_bytes, backupCount=backup_count
    )
    logger.addHandler(handler)

    formatter = CustomFormatter("%(asctime)s %(message)s")
    handler.setFormatter(formatter)

    return logger


def get_delay(speed: int):
    if speed == 0:
        return 0
    elif speed == 1:
        return 1 / random.randint(1, 300)
    elif speed == 2:
        return 1 / random.randint(300, 500)
    elif speed == 3:
        return 1 / random.randint(500, 1000)
    else:
        return 1 / random.randint(2000, 3000)


log_path = "karaf-logs/karaf.log"
max_size_bytes = 2 * 1024 * 1024  # в мегабайтах
backup_count = 10
speed = 4  # скорость, с которой растер размер файла (от 0 - выполнить 1 итерацию, до 4 - максимально быстро)

logger = setup_logging(log_path, max_size_bytes, backup_count)
delay = get_delay(speed)

if __name__ == "__main__":
    while True:
        logger.info(fake_log_message())
        if delay > 0:
            time.sleep(delay)
        else:
            break
