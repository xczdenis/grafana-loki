## Запустить
Сначала нужно создать файл `.env`:
```bash
make env
```

Запустить в докере:
```bash
make run
```

Остановить:
```bash
make down
```

Посмотреть логи:
```bash
make logs
```

Зайти в контейнер:
```bash
make bash
or
make sh
```

## Loki

### Ошибка "Maximum active stream limit exceeded"

Документация: секция [limits_config](https://grafana.com/docs/loki/latest/configure/#limits_config)

Ошибка:
```text
level=warn ts=2024-03-07T07:47:47.662807709Z caller=grpc_logging.go:57 method=/logproto.Pusher/Push duration=270.208µs 
err="rpc error: code = Code(429) desc = Maximum active stream limit exceeded, reduce the number of active streams 
(reduce labels or reduce label values), or contact your Loki administrator to see if the limit can be increased, 
user: 'fake'" msg=gRPC
```

Настройки конфига локи:
```yaml
# Maximum number of active streams per user, per ingester. 0 to disable.
# CLI flag: -ingester.max-streams-per-user
[max_streams_per_user: <int> | default = 0]
```

Чем больше уникальных меток, тем больше потоков. Надо избегать уникальных меток, например, со значениями UUID.

Эта ошибка связана с ограничением на количество активных потоков данных (streams), которые пользователь 
может одновременно отправлять в Loki. Каждый поток представляет собой уникальный набор лейблов. 
Если количество таких уникальных наборов превышает установленный лимит, Loki начинает отклонять новые потоки с 
данной ошибкой. 

Это может произойти, если отправляются логи с большим количеством уникальных комбинаций меток.

Нужно или увеличить лимит `max_streams_per_user` в конфигурации Loki, или оптимизировать количество и структуру меток, 
чтобы уменьшить количество уникальных потоков.

Увеличение этого лимита может негативно сказаться на производительности и управляемости.

Пример конфига Loki:
```yaml
limits_config:
  max_streams_per_user: 10000        # применяется на уровне 1 инстанса [max_streams_per_user: <int> | default = 0]  
  max_global_streams_per_user: 10000 # применяется на уровне кластера [max_global_streams_per_user: <int> | default = 5000]
```


### grpc: received message larger than max
Документация: секция [server](https://grafana.com/docs/loki/latest/configure/#server).

Ошибка:
```text
level=error ts=2024-03-07T07:36:10.920445387Z caller=scheduler_processor.go:208 org_id=fake traceID=2c49e1508f422c14 
frontend=192.168.0.4:9095 msg="error notifying frontend about finished query" err="rpc error: code = ResourceExhausted 
desc = grpc: received message larger than max (4250237 vs. 4194304)"
```

Настройки конфига локи:
```yaml
# Limit on the size of a gRPC message this server can receive (bytes).
# CLI flag: -server.grpc-max-recv-msg-size-bytes
[grpc_server_max_recv_msg_size: <int> | default = 4194304]

# Limit on the size of a gRPC message this server can send (bytes).
# CLI flag: -server.grpc-max-send-msg-size-bytes
[grpc_server_max_send_msg_size: <int> | default = 4194304]
```

Ошибка лечится настройками:
* `grpc_server_max_recv_msg_size`: это параметр, который устанавливает максимальный размер gRPC сообщения, 
которое может быть принято сервером. Если сообщение превышает этот размер, оно будет отклонено 
с ошибкой ResourceExhausted.
* `grpc_server_max_send_msg_size`: аналогично, этот параметр определяет максимальный размер сообщения, 
который сервер может отправить клиенту через gRPC. Сообщения, превышающие этот лимит, не будут отправлены, 
и операция завершится с ошибкой.

Пример конфига Loki:
```yaml
server:
  http_listen_port: 3100
  grpc_server_max_recv_msg_size: 8388608  # 8 MB
  grpc_server_max_send_msg_size: 8388608  # 8 MB
```

### Настройка max_chunk_age
Настройка `max_chunk_age` см. здесь: [https://grafana.com/docs/loki/latest/configure/#accept-out-of-order-writes]()

Насколько далеко в прошлом могут быть принятые записи журнала. По умолчанию 2 часа.

Пример если `max_chunk_age` не задан (равен 2 по умолчанию):
```text
==========================================
Текущая дата: 01.03.2024 12:00:00
Нужно учитывать, что UTC - это +3 часа
------------------------------------------
Логи:
01.03.2024 05:00:00 лог 1 - не будет выведен т.к. 5+3=8, 12-8=4, 4 часа - старше 2х часов от текущей даты
01.03.2024 06:00:00 лог 1 - не будет выведен т.к. 6+3=9, 12-9=3, 3 часа - старше 2х часов от текущей даты
01.03.2024 07:00:00 лог 1 - будет выведен т.к. 7+3=10, 12-10=2, 2 часа - не старше 2х часов от текущей даты
01.03.2024 08:00:00 лог 1 - будет выведен т.к. 8+3=11, 12-11=1, 1 часа - не старше 2х часов от текущей даты
01.03.2024 09:00:00 лог 1 - будет выведен т.к. 9+3=12, 12-12=0, задержки нет - не старше 2х часов от текущей даты
01.03.2024 10:00:00 лог 1 - не будет выведен т.к. 10+3=13, 13:00 - это уже в будущем по
                               сравнению с 12:00. Будет ошибка has timestamp too new: 2024-03-01T10:00:00Z
```