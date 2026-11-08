# postgres_pull

Пулер соединений для PostgreSQL на Go. Клиенты подключаются к пулеру как к обычному Postgres, а он раздаёт им ограниченный пул настоящих соединений с базой: в режиме `transaction` соединение закрепляется за клиентом только на время транзакции.

> Статус: каркас. Сейчас пулер на этапе продумывания логики

## Быстрый старт

```bash
cp .env.example .env
make db-up      # Postgres в Docker на :5432
make run        # пулер на :6432
make psql       # подключиться через пулер
```

Всё в Docker: `make up` / `make down`.

Без `make` (Windows):

```powershell
docker compose up -d postgres
go run ./cmd/pooler
psql "postgres://app:app@localhost:6432/app?sslmode=disable"
```

## Конфигурация

| Переменная | По умолчанию | Описание |
|---|---|---|
| `LISTEN_ADDR` | `0.0.0.0:6432` | адрес, на котором слушает пулер |
| `BACKEND_ADDR` | `localhost:5432` | адрес Postgres |
| `POOL_MODE` | `transaction` | `session` или `transaction` |
| `POOL_SIZE` | `20` | число настоящих соединений с базой |
| `CLIENT_WAIT_TIMEOUT` | `5s` | сколько клиент ждёт свободное соединение |
| `LOG_LEVEL` | `info` | `debug`, `info`, `warn`, `error` |

Переменные окружения имеют приоритет над `.env`.

## Структура

```
cmd/pooler/          точка входа, сигналы, логгер
internal/config/     конфиг из окружения и .env
internal/proxy/      приём клиентов и пересылка трафика
internal/protocol/   (план) сообщения протокола Postgres
internal/pool/       (план) пул соединений с базой и очередь клиентов
```

## План

1. **TCP-прокси** — готово.
2. **Протокол.** Разбор стартового сообщения, `SSLRequest`, аутентификация (cleartext, затем SCRAM-SHA-256), чтение сообщений по типу и длине.
3. **Session pooling.** Пул соединений, соединение выдаётся на всю сессию клиента, очередь ожидания с таймаутом.
4. **Transaction pooling.** Возврат соединения в пул по `ReadyForQuery` со статусом `I`, `DISCARD ALL` перед выдачей другому клиенту, откат при обрыве клиента.
5. **Extended protocol.** `Parse`/`Bind`/`Execute`/`Sync`, отслеживание prepared statements при смене соединения.
6. **Наблюдаемость.** Метрики Prometheus: ожидающие клиенты, время ожидания, загрузка пула.
7. **Бенчмарк.** pgbench на 500 клиентов при `max_connections = 100`: напрямую, через пулер, через PgBouncer.
