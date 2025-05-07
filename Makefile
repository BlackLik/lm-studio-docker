# Makefile для lm-studio-docker

# Режим запуска: cpu (по умолчанию) или cuda
MODE ?= cpu

# Путь к папке с docker-compose
COMPOSE_DIR := deployment
COMPOSE_CPU   := $(COMPOSE_DIR)/docker-compose.cpu.yaml
COMPOSE_CUDA  := $(COMPOSE_DIR)/docker-compose.cuda.yaml

# Выбираем файл compose в зависимости от MODE
ifeq ($(MODE),cuda)
	COMPOSE_FILE := $(COMPOSE_CUDA)
else
	COMPOSE_FILE := $(COMPOSE_CPU)
endif

# Полная команда: сборка + поднятие
.PHONY: run
run: build up

# Собираем образы
.PHONY: build
build:
	docker-compose -f $(COMPOSE_FILE) build

# Поднимаем контейнеры
.PHONY: up
up:
	docker-compose -f $(COMPOSE_FILE) up --force-recreate -d

# Останавливаем и удаляем контейнеры
.PHONY: down
down:
	docker-compose -f $(COMPOSE_FILE) down
