# goalgo

Платформа для практики алгоритмов в браузере. Статический сайт на Hugo с встроенным терминалом — задачи решаются прямо на странице в vim, внутри изолированного Docker-контейнера.

---

## Репозитории организации

| Репозиторий | Назначение | Публичность |
|-------------|-----------|-------------|
| [gotogolang.github.io](https://github.com/gotogolang/gotogolang.github.io) | Центральный хаб: `platform.toml`, `docker-compose.yml`, документация | публичный |
| [site-config](https://github.com/gotogolang/site-config) | Hugo config, layouts, shortcodes, GitHub Actions деплой | приватный |
| [site-content](https://github.com/gotogolang/site-content) | Контент сайта: страницы задач, блог (Hugo markdown) | публичный |
| [themes](https://github.com/gotogolang/themes) | Hugo-темы (`compose/`) | приватный |
| [exercises](https://github.com/gotogolang/exercises) | Упражнения: условия, заготовки кода, тесты (`go/`, `python/`) | публичный |
| [docker-images](https://github.com/gotogolang/docker-images) | Dockerfile среды исполнения (`go/`, `python/`) | приватный |
| [vim-configs](https://github.com/gotogolang/vim-configs) | Конфиг vim + плагины (`go/`, `python/`) | приватный |
| [tps-backend](https://github.com/gotogolang/tps-backend) | Go-микросервисы: gateway, session-service, pool-service | приватный |
| [tps-widget](https://github.com/gotogolang/tps-widget) | JS-виджет терминала (xterm.js) | приватный |

---

## Архитектура

```
GitHub Pages (статика)
└── Hugo (site-config + site-content + themes/compose)
    └── {{< terminal pack="go" exercise="..." >}}
        └── tps-widget (JS, xterm.js)
            └── WebSocket → gateway :8080

VPS (микросервисы, Go / Chi)
├── :8080  gateway          — REST API, WebSocket-прокси
├── :8081  session-service  — JWT-токены
└── :8082  pool-service     — Docker-пул контейнеров [go]
               └── docker-images/go @ v0.1.0
                   └── vim-configs/go @ v0.1.0
```

---

## Дерево зависимостей

```
gotogolang.github.io / platform.toml
│
├── site-config                     (Hugo конфиг + деплой)
│   └── themes/compose              (форк Hugo-темы)
│
├── site-content                    (страницы + блог)
│
├── tps-widget                      (JS-бандл)
│
├── tps-backend                     (Go-сервисы)
│
├── exercises/go                    (упражнения)
│
└── docker-images/go                (образ контейнера)
    └── vim-configs/go              (конфиг vim)
```

---

## Управление версиями

Версии всех компонентов декларируются в [`platform.toml`](platform.toml).

```toml
[pools.go]
image       = "gotogolang/tps-go:v0.1.0"
pool_size   = 3
timeout_sec = 3600
```

Обновить компонент:
```bash
make update COMPONENT=docker-images/go VERSION=v1.1.0
```

Каждый компонент содержит собственный `component.toml` со своими зависимостями.

---

## Быстрый старт (локальная разработка)

```bash
# 1. Клонировать хаб со всеми субмодулями
git clone --recurse-submodules https://github.com/gotogolang/gotogolang.github.io
cd gotogolang.github.io

# 2. Настроить окружение
cp .env.example .env
# отредактировать .env: JWT_SECRET, EXERCISES_HOST_PATH

# 3. Собрать Docker-образ контейнера (Go)
make build-image LANG=go

# 4. Собрать JS-виджет
make build-widget

# 5. Запустить стек
make up
# gateway:  http://localhost:8080
# sessions: http://localhost:8081
# pool go:  http://localhost:8082

# 6. Остановить
make down
```

---

## Деплой

### Сайт (GitHub Pages)
Деплой запускается автоматически из `site-config` при:
- пуше в `main` репо `site-config`
- `repository_dispatch: content-updated` (пуш в `site-content`)
- вручную через `workflow_dispatch`

Требуется секрет `DEPLOY_TOKEN` (GitHub PAT) в настройках репозитория.

### Бэкенд (VPS)
```bash
# На сервере
docker compose pull
docker compose up -d
```

---

## Добавление нового языка

1. Добавить `vim-configs/{lang}/`
2. Добавить `docker-images/{lang}/Dockerfile`
3. Добавить `exercises/{lang}/`
4. Запустить ещё один инстанс `pool-service` на свободном порту
5. Обновить `POOL_SERVICES` в gateway
6. Обновить `platform.toml`
