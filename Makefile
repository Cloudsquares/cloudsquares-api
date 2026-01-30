# Makefile — Упрощает команды Docker Compose для разработки и продакшена

# Переменные окружения по умолчанию
ENV_FILE_TEST=.env.test
ENV_FILE_DEV=.env.development
ENV_FILE_PROD=.env.production

# ========================
# 👨‍💻 TEST
# ========================

.PHONY: test-build test test-file test-db-create test-db-migrate test-db-prepare

test-build:
	docker compose --env-file $(ENV_FILE_TEST) build web-test

test:
	make test-build
	docker compose --env-file $(ENV_FILE_TEST) run --rm web-test bundle exec rspec

test-file:
	make test-build
	docker compose --env-file $(ENV_FILE_TEST) run --rm web-test bundle exec rspec $(f)

test-db-create:
	docker compose --env-file $(ENV_FILE_TEST) run --rm web-test bundle exec rails db:create

test-db-migrate:
	docker compose --env-file $(ENV_FILE_TEST) run --rm web-test bundle exec rails db:migrate

test-db-prepare:
	docker compose --env-file $(ENV_FILE_TEST) run --rm web-test bundle exec rails db:prepare



# ========================
# 👨‍💻 DEVELOPMENT
# ========================

## 🛠 Сборка dev-образа без запуска контейнеров
build-dev:
	docker compose --env-file $(ENV_FILE_DEV) build

## 🚀 Запустить dev-среду (локально с volumes и портами)
up-dev:
	docker compose --env-file $(ENV_FILE_DEV) up --build

## 🧹 Остановить и удалить dev-контейнеры и volume
clean-dev:
	docker compose --env-file $(ENV_FILE_DEV) down -v

## 🐛 Логи контейнеров dev-режима
logs-dev:
	docker compose --env-file $(ENV_FILE_DEV) logs -ft

## 🔧 Установка гемов через bundle install внутри контейнера
bundle-install:
	docker compose --env-file $(ENV_FILE_DEV) exec web bundle install

## 🔧 Создание БД, миграции и сиды (db:prepare)
db-prepare:
	docker compose --env-file $(ENV_FILE_DEV) exec web bin/rails db:prepare

## 📦 Применить только миграции (db:migrate)
db-migrate:
	docker compose --env-file $(ENV_FILE_DEV) exec web bin/rails db:migrate

## ⬆️ Выполнить конкретную миграцию по VERSION
db-up:
	docker compose --env-file $(ENV_FILE_DEV) exec web bin/rails db:migrate:up VERSION=$(VERSION)

## 🧪 Откат последней миграции (db:rollback)
db-rollback:
	docker compose --env-file $(ENV_FILE_DEV) exec web bin/rails db:rollback STEP=$(STEP)

## ⬇️ Откатить конкретную миграцию по VERSION
db-down:
	docker compose --env-file $(ENV_FILE_DEV) exec web bin/rails db:migrate:down VERSION=$(VERSION)

## 🌱 Заполнить тестовыми данными из seeds.rb (db:seed)
db-seed:
	docker compose --env-file $(ENV_FILE_DEV) exec web bin/rails db:seed --trace

## 💣 Полный сброс базы данных и повторный запуск миграций + seed
db-reset:
	docker compose --env-file $(ENV_FILE_DEV) exec web bin/rails db:migrate:reset


## 🧬 Проверить статус миграций (db:migrate:status)
db-status:
	docker compose --env-file $(ENV_FILE_DEV) exec web bin/rails db:migrate:status

## 💬 Открыть Rails-консоль внутри контейнера
console:
	docker compose --env-file $(ENV_FILE_DEV) exec web bin/rails console

## 🎮 Генерация API-контроллера (например: make controller NAME=api/v1/users)
controller:
	@if [ -z "$(NAME)" ]; then \
	  echo "❌ Пожалуйста, укажи NAME (например, NAME=api/v1/users)"; \
	else \
	  docker compose --env-file $(ENV_FILE_DEV) exec web bin/rails generate controller $(NAME) --skip-template-engine --no-assets --api; \
	fi

## Просмотр всех существующих роутов
routes:
	docker compose --env-file $(ENV_FILE_DEV) exec web bin/rails routes

## Проверка установки гема
check-gem:
	@if [ -z "$(GEM)" ]; then \
	  echo "❌ Пожалуйста, укажи NAME (например, NAME=friendly_id)"; \
	else \
	  docker compose --env-file $(ENV_FILE_DEV) exec web bundle show $(GEM); \
	fi


# ========================
# 🧰 ONE-SHOT SETUP (new machine)
# ========================

.PHONY: setup check-docker check-daemon ensure-envs create-network prepare-db-dev prepare-db-test up-dev-detached doctor

# ——— Автоопределение платформы для мультиарх ———
UNAME_M := $(shell uname -m)
ifeq ($(UNAME_M),x86_64)
  DEFAULT_PLATFORM := linux/amd64
else ifeq ($(UNAME_M),aarch64)
  DEFAULT_PLATFORM := linux/arm64
else
  DEFAULT_PLATFORM := linux/amd64
endif

# Экспортируем для docker/compose; на mac M1/M2 можно переопределить перед запуском:
#   export DOCKER_DEFAULT_PLATFORM=linux/arm64
export DOCKER_DEFAULT_PLATFORM ?= $(DEFAULT_PLATFORM)

# Унифицированная команда compose (можно вызвать с sudo при желании: DC='sudo docker compose' make setup)
DC ?= docker compose

## 🧪 Проверка наличия Docker/Compose (CLI)
check-docker:
	@command -v docker >/dev/null 2>&1 || { echo "❌ Docker не установлен или не в PATH"; exit 1; }
	@$(DC) version >/dev/null 2>&1 || { echo "❌ Docker Compose v2 не найден (нужен 'docker compose', не 'docker-compose')"; exit 1; }
	@echo "✅ Docker/Compose CLI ок"

## 🧯 Проверка подключения к демону и прав
check-daemon:
	@docker info >/dev/null 2>&1 || { \
	  echo "❌ Не удаётся подключиться к docker-демону."; \
	  echo "   Linux: запусти сервис →  sudo systemctl enable --now docker"; \
	  echo "          добавь себя в группу →  sudo usermod -aG docker $$USER && newgrp docker"; \
	  exit 1; \
	}
	@echo "✅ Docker daemon доступен"

## 🌐 Внешняя сеть для compose (если её нет)
create-network:
	@docker network create cloudsquares-net >/dev/null 2>&1 && echo "✅ Создана сеть cloudsquares-net" || echo "• Сеть cloudsquares-net уже есть"

## 🗝️ Создание .env.* из примеров, если их нет (без перезаписи)
ensure-envs:
	@set -e; \
	copy_if_absent() { \
	  src="$$1"; dst="$$2"; \
	  if [ -f "$$dst" ]; then echo "• найден $$dst — пропускаем"; \
	  else if [ -f "$$src" ]; then cp "$$src" "$$dst"; echo "✅ скопирован $$src → $$dst"; \
	  else echo "⚠️  файл $$dst не найден и нет шаблона $$src — создай вручную"; fi; fi; \
	}; \
	copy_if_absent ".env.development.example" "$(ENV_FILE_DEV)"; \
	copy_if_absent ".env.test.example"        "$(ENV_FILE_TEST)"; \
	copy_if_absent ".env.production.example"  "$(ENV_FILE_PROD)"

## 🗄️ Подготовка базы и сервисов в dev
## 🗄️ Подготовка базы и сервисов в dev (поднимаем deps → миграции → поднимаем app)
prepare-db-dev:
	# 1) Собираем образы (свежие тэги)
	$(DC) --env-file $(ENV_FILE_DEV) build --pull
	# 2) Поднимаем только инфраструктуру и ждём healthchecks
	$(DC) --env-file $(ENV_FILE_DEV) up -d --wait db redis
	# 3) Прогоняем миграции до старта web (db:prepare включает create+migrate)
	$(DC) --env-file $(ENV_FILE_DEV) run --rm web bin/rails db:prepare
	#   На случай кастомных rake-тасков/нового поведения — явно запустим migrate
	-$(DC) --env-file $(ENV_FILE_DEV) run --rm web bin/rails db:migrate
#	# 4) Теперь поднимаем приложение и фоновые воркеры и ждём healthchecks
#	$(DC) --env-file $(ENV_FILE_DEV) up -d --wait web sidekiq
#	#   web-test (если есть) поднимем без ожидания — он у тебя "sleep infinity"
#	-@if $(DC) --env-file $(ENV_FILE_DEV) config --services | grep -qx "web-test"; then \
#	  $(DC) --env-file $(ENV_FILE_DEV) up -d web-test; \
#	fi


## 🧪 Подготовка test-среды (опционально, если есть сервис web-test)
prepare-db-test:
	@set -e; \
	if $(DC) --env-file $(ENV_FILE_TEST) config --services | grep -qx "web-test"; then \
	  echo "🧪 Найден сервис web-test — готовим test БД…"; \
	  $(DC) --env-file $(ENV_FILE_TEST) build --pull web-test; \
	  $(DC) --env-file $(ENV_FILE_TEST) run --rm web-test bin/rails db:prepare; \
	else \
	  echo "ℹ️  Сервис web-test не найден — пропускаем подготовку test БД"; \
	fi

## 🚀 Поднять dev-стек в фоне
up-dev-detached:
	$(DC) --env-file $(ENV_FILE_DEV) up -d

## 🧭 Полная настройка проекта (без старта сервисов)
setup: check-docker check-daemon ensure-envs create-network
	@echo "🔧 Сборка и подготовка dev окружения…"
	$(MAKE) prepare-db-dev
	@echo "🧪 Подготовка test окружения…"
	$(MAKE) prepare-db-test
	@echo ""
	@echo "✅ Готово! Окружение и база подготовлены."
	@echo "   • Запустить локально: make up-dev"
	@echo "   • Логи после старта: make logs-dev"
	@echo "   • Полный reset: make reset-dev-hard"

## 🩺 Диагностика окружения (по желанию)
doctor:
	@echo "Host arch: $$(uname -m)"; \
	echo "Docker daemon: $$(docker version --format '{{.Server.Arch}}/{{.Server.Os}}')"; \
	echo "DOCKER_DEFAULT_PLATFORM=$(DOCKER_DEFAULT_PLATFORM)"; \
	echo "Compose services (platform flags):"; \
	$(DC) config | grep -n 'platform:' || echo "  (platform не задан явно — используется DOCKER_DEFAULT_PLATFORM)"

# ========================
# 🧨 HARD RESET DEV ENV (improved)
# ========================

.PHONY: reset-dev reset-dev-hard _down-dev _down-test _rm-leftovers _rm-project-images _prune-dangling _rm-project-volumes

DC ?= docker compose

## 🧹 Полная очистка dev/test окружения (контейнеры + именованные тома из compose)
reset-dev: _down-dev _down-test _rm-leftovers
	@echo "✅ Dev/test окружение очищено. .env файлы сохранены."
	@echo "   → Для запуска заново: make setup"

_down-dev:
	@echo "🧹 Сносим dev-сервисы и тома…"
	-$(DC) --env-file $(ENV_FILE_DEV) down -v --remove-orphans

_down-test:
	@echo "🧪 Сносим test-сервисы и тома (если есть)…"
	-$(DC) --env-file $(ENV_FILE_TEST) down -v --remove-orphans

_rm-leftovers:
	@echo "🗑 Удаляем возможные оставшиеся контейнеры по именам (если есть)…"
	-@docker rm -f cloudsquares-api cloudsquares-sidekiq cloudsquares-api-test cloudsquares-db cloudsquares-redis >/dev/null 2>&1 || true
	@echo "🧽 Чистим tmp/pids/server.pid (на всякий случай)…"
	-@rm -f tmp/pids/server.pid 2>/dev/null || true

## 🧨 Жёсткая очистка: + удаление проектных образов и висячих слоёв/томов
reset-dev-hard: reset-dev _rm-project-images _rm-project-volumes _prune-dangling
	@echo "✅ Полная очистка завершена."
	@echo "   → Для запуска заново: make setup"

# Удаляем ЛЮБОЙ образ проекта по маске cloudsquares-api-* (включая :latest)
_rm-project-images:
	@echo "🧯 Удаляем локальные образы проекта (cloudsquares-api-*)…"
	@ids=$$(docker image ls --filter=reference='cloudsquares-api-*' -q); \
	if [ -n "$$ids" ]; then docker image rm -f $$ids; else echo "• Нечего удалять по маске cloudsquares-api-*"; fi

# Удаляем локальные volumes проекта по имени и подчистим висячие (dangling)
# ВНИМАНИЕ: prune удаляет ТОЛЬКО неиспользуемые (ни к чему не подключённые) тома
_rm-project-volumes:
	@echo "🧺 Удаляем project-scoped volumes (по имени cloudsquares-api*)…"
	@vols=$$(docker volume ls -q --filter name='cloudsquares-api'); \
	if [ -n "$$vols" ]; then docker volume rm $$vols; else echo "• Нечего удалять по имени cloudsquares-api*"; fi

_prune-dangling:
	@echo "🧽 Чистим dangling-образы и неиспользуемые тома…"
	-@docker image prune -f >/dev/null 2>&1 || true
	-@docker volume prune -f >/dev/null 2>&1 || true



# ========================
# 🚀 PRODUCTION
# ========================

## 📦 Применить миграции в продакшене
db-migrate-prod:
	docker compose -f docker-compose.yml -f docker-compose.prod.yml --env-file $(ENV_FILE_PROD) exec web bin/rails db:migrate

## 🛠 Сборка production-образа без запуска контейнеров
build-prod:
	docker compose -f docker-compose.yml -f docker-compose.prod.yml --env-file $(ENV_FILE_PROD) build

## 🚀 Запустить production (без volume и открытых портов)
up-prod:
	docker compose -f docker-compose.yml -f docker-compose.prod.yml --env-file $(ENV_FILE_PROD) up --build -d

## 🧹 Остановить и удалить продакшн контейнеры + volumes
clean-prod:
	docker compose -f docker-compose.yml -f docker-compose.prod.yml --env-file $(ENV_FILE_PROD) down -v

## 🐛 Логи продакшн-контейнеров
logs-prod:
	docker compose -f docker-compose.yml -f docker-compose.prod.yml --env-file $(ENV_FILE_PROD) logs -ft

## 🐛 Логи бекенд контейнера
logs-backend:
	docker logs -f fastyshop-backend

## 🔧 Создание БД, миграции и сиды (db:prepare)
db-prepare-prod:
	docker compose -f docker-compose.yml -f docker-compose.prod.yml --env-file $(ENV_FILE_PROD) exec web bin/rails db:prepare

## 🌱 Заполнить тестовыми данными из seeds.rb (db:seed)
db-seed-prod:
	docker compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.production exec web bin/rails db:seed

# Запуск консоли в контейнере продакшена
rails-c-prod:
	docker compose -f docker-compose.yml -f docker-compose.prod.yml --env-file .env.production exec web bin/rails console

sidekiq:
	docker compose up sidekiq

# ========================
# 📖 SWAGGER / API DOCS
# ========================

## 📝 Generate Swagger/OpenAPI documentation from rswag specs
swagger-generate:
	docker compose --env-file $(ENV_FILE_DEV) exec web bundle exec rake rswag:specs:swaggerize

## 📝 Generate Swagger documentation (test environment)
swagger-generate-test:
	make test-build
	docker compose --env-file $(ENV_FILE_TEST) run --rm web-test bundle exec rake rswag:specs:swaggerize

## 🧪 Run only swagger-tagged request specs
swagger-specs:
	make test-build
	docker compose --env-file $(ENV_FILE_TEST) run --rm web-test bundle exec rspec spec/requests --format documentation

## 🔍 Validate generated swagger spec (requires swagger-cli: npm install -g @apidevtools/swagger-cli)
swagger-validate:
	@if [ -f "swagger/v1/swagger.yaml" ]; then \
		npx @apidevtools/swagger-cli validate swagger/v1/swagger.yaml; \
	else \
		echo "❌ swagger/v1/swagger.yaml not found. Run 'make swagger-generate' first."; \
	fi

## 🌐 Open Swagger UI in browser (dev server must be running)
swagger-ui:
	@echo "Opening Swagger UI at http://localhost:3001/api-docs"
	@xdg-open http://localhost:3001/api-docs 2>/dev/null || open http://localhost:3001/api-docs 2>/dev/null || echo "Visit: http://localhost:3001/api-docs"
