DEFAULT_PROJECT_NAME=grafana-loki
COMPOSE_PROFILE_DEFAULT=""--profile default""
COMPOSE_PROFILE_GRAFANA=""--profile grafana""

# define standard colors
ifneq (,$(findstring xterm,${TERM}))
	BLACK        := $(shell printf "\033[30m")
	RED          := $(shell printf "\033[31m")
	GREEN        := $(shell printf "\033[32m")
	YELLOW       := $(shell printf "\033[33m")
	PURPLE       := $(shell printf "\033[34m")
	PINK         := $(shell printf "\033[35m")
	BLUE         := $(shell printf "\033[36m")
	ORANGE       := $(shell printf "\033[93m")
	WHITE        := $(shell printf "\033[97m")
	RESET        := $(shell printf "\033[00m")
	INFO         := $(shell printf "\033[36m")
	SUCCESS      := $(shell printf "\033[32m")
	WARNING      := $(shell printf "\033[33m")
	DANGER       := $(shell printf "\033[31m")
else
	BLACK        := ""
	RED          := ""
	GREEN        := ""
	YELLOW       := ""
	BLUE         := ""
	PURPLE       := ""
	ORANGE       := ""
	WHITE        := ""
	RESET        := ""
	INFO         := ""
	SUCCESS      := ""
	WARNING      := ""
	DANGER       := ""
endif

# read env variables from .env
ifneq (,$(wildcard ./.env))
	include .env
	export
endif

# set envs if they are not defined
ifeq ($(PROJECT_NAME),)
	PROJECT_NAME=$(DEFAULT_PROJECT_NAME)
endif
ifeq ($(DOCKER_BUILDKIT),)
	DOCKER_BUILDKIT=1
endif


define log
	@echo ""
	@echo "${WHITE}----------------------------------------${RESET}"
	@echo "${BLUE}$(strip ${1})${RESET}"
	@echo "${WHITE}----------------------------------------${RESET}"
endef


define run_docker_compose
	@DOCKER_BUILDKIT=${DOCKER_BUILDKIT} COMPOSE_PROJECT_NAME=${PROJECT_NAME} docker-compose $(strip ${1})
endef


# Function to check if service is available
define check_service
	@nc -z $(2) $(3) || (echo "${DANGER}ERROR:${RESET} $(1) at ${INFO}$(2):$(3)${RESET} is not available.${RESET}" && exit 1)
endef


# check if the Makefile is available: it should return PONG
.PHONY: ping
ping:
	echo "PONG"


# display info about: current envs, project name etc.
.PHONY: info
info:
	$(call log, INFORMATION)
	@echo "PROJECT_NAME        = ${INFO}${PROJECT_NAME}${RESET}"
	@echo "DOCKER_IMG_PLATFORM = ${INFO}${DOCKER_IMG_PLATFORM}${RESET}"


# display info about running docker containers, images, volumes
.PHONY: di
di:
	@echo "${INFO}Running containers:${RESET}"
	@docker ps
	@echo "${INFO}All containers:${RESET}"
	@docker ps -a
	@echo "${INFO}Images:${RESET}"
	@docker images
	@echo "${INFO}Volumes:${RESET}"
	@docker volume ls
	@echo "${INFO}Networks:${RESET}"
	@docker network ls


# check if Postgres is available
.PHONY: check_pg
check_pg:
	$(call check_service,"Postgres",${POSTGRES_HOST},${POSTGRES_PORT})


# remove all existing containers, volumes, images
.PHONY: remove
remove:
	@clear
	@echo "${RED}----------------!!! DANGER !!!----------------"
	@echo "Вы собираетесь удалить все неиспользуемые образы, контейнеры и тома."
	@echo "Будут удалены все незапущенные контейнеры, все образы для незапущенных контейнеров и все тома для незапущенных контейнеров"
	@read -p "${ORANGE}Вы точно уверены, что хотите продолжить? [yes/n]: ${RESET}" TAG \
	&& if [ "_$${TAG}" != "_yes" ]; then echo "Nothing happened"; exit 1 ; fi
	docker system prune -a --volumes --force && docker network prune


# create .env file if it is not exist
.PHONY: env
env:
	@if [ -f .env ]; then \
		read -p "File ${GREEN}.env${RESET} already exists. Overwrite it [y/n]:${RESET} " yn; \
        case $$yn in \
            [Yy]* ) cp .env.template .env; echo "File ${GREEN}.env${RESET} has been overwritten!";; \
            * ) echo "Nothing happened";; \
        esac \
    else \
        cp .env.template .env; \
        echo "File ${GREEN}.env${RESET} created from ${GREEN}.env.template${RESET}!"; \
    fi


# build all docker images
.PHONY: build build-profile
build:
	$(call log, Build all images)
	$(call run_docker_compose, ${COMPOSE_PROFILE_DEFAULT} build)
	$(call run_docker_compose, ${COMPOSE_PROFILE_GRAFANA} build)
build-profile:
	$(call log, Build images for profile ${PINK}${p}${RESET})
	$(call run_docker_compose, --profile ${p} build)


# stop and remove all running containers
.PHONY: down
down:
	$(call log, Down containers)
	$(call run_docker_compose, ${COMPOSE_PROFILE_DEFAULT} down)
	$(call run_docker_compose, ${COMPOSE_PROFILE_GRAFANA} down)

# build and run docker containers in demon mode
.PHONY: run
run: down
	$(call log, Run containers)
	$(call run_docker_compose, ${COMPOSE_PROFILE_DEFAULT} up -d --build)


.PHONY: rung
rung: down
	$(call log, Run only containers for profile ${PINK}grafana${RESET})
	$(call run_docker_compose, ${COMPOSE_PROFILE_GRAFANA} up -d --build)


# run docker containers in demon mode
.PHONY: up
up:
	$(call log, Run docker containers in daemon mode)
	$(call run_docker_compose, ${COMPOSE_PROFILE_DEFAULT} up -d --build)


# show service's logs (e.g.: make logs s=proxy)
.PHONY: logs _logs
logs:
	@if [ -z "${s}" ]; then \
		read -p "${ORANGE}Container name: ${RESET}" _TAG && \
		make _logs s="$${_TAG}"; \
	else \
	    make _logs s="${s}"; \
	fi
_logs:
	$(call run_docker_compose, logs -f ${s})


# run bash into container
.PHONY: bash _bash
bash:
	@if [ -z "${s}" ]; then \
		read -p "${ORANGE}Container name: ${RESET}" _TAG && \
		make _bash s="$${_TAG}"; \
	else \
	    make _bash s="${s}"; \
	fi
_bash:
	$(call run_docker_compose, exec -it ${s} bash)


# run sh into container (e.g. for Redis)
.PHONY: sh _sh
sh:
	@if [ -z "${s}" ]; then \
		read -p "${ORANGE}Container name: ${RESET}" _TAG && \
		make _sh s="$${_TAG}"; \
	else \
	    make _sh s="${s}"; \
	fi
_sh:
	$(call run_docker_compose, exec -it ${s} sh)


# stop services
.PHONY: stop stops
stop:
	@read -p "${ORANGE}Service name (press Enter to stop all services): ${RESET}" _TAG && \
	if [ "_$${_TAG}" != "_" ]; then \
		make stops s="$${_TAG}"; \
	else \
	    make stopall; \
	fi
stops:
	$(call log, Stop container)
	$(call run_docker_compose, ${COMPOSE_PROFILE_DEFAULT} stop ${s})
stopall:
	$(call log, Stop all containers)
	$(call run_docker_compose, ${COMPOSE_PROFILE_DEFAULT} stop)
	$(call run_docker_compose, ${COMPOSE_PROFILE_GRAFANA} stop)


# start services (e.g.: start s=redis)
.PHONY: start _start
start:
	@if [ -z "${s}" ]; then \
		read -p "${ORANGE}Container name: ${RESET}" _TAG && \
		make _start s="$${_TAG}"; \
	else \
	    make _start s="${s}"; \
	fi
_start:
	$(call run_docker_compose, ${COMPOSE_PROFILE_DEFAULT} start ${s})


# show docker-compose status
.PHONY: status status-all
status:
	$(call run_docker_compose, ps)
status-all:
	$(call run_docker_compose, ps -a)


# remove all stopped containers/unused images/unused volumes/unused networks
.PHONY: prune prune-с prune-i prune-v prune-n
prune:
	@clear
	@echo "${DANGER}----------------!!! DANGER !!!----------------"
	@echo "Будет выполнена команда <${INFO}docker system prune${DANGER}>."
	@echo "${DANGER}Будут удалены все не запущенные контейнеры, сети, зависшие образы и очищен кэш."
	@read -p "${WARNING}Вы точно уверены, что хотите продолжить? [yes/n]: ${RESET}" TAG \
	&& if [ "_$${TAG}" != "_yes" ]; then echo "Nothing happened"; exit 1 ; fi
	$(call log, Docker system prune)
	docker system prune
prune-c:
	@clear
	@echo "${DANGER}----------------!!! DANGER !!!----------------"
	@echo "Будет выполнена команда <${INFO}docker container prune${DANGER}>."
	@echo "${DANGER}Будут удалены все не запущенные контейнеры"
	@read -p "${WARNING}Вы точно уверены, что хотите продолжить? [yes/n]: ${RESET}" TAG \
	&& if [ "_$${TAG}" != "_yes" ]; then echo "Nothing happened"; exit 1 ; fi
	$(call log, Remove all stopped containers)
	docker container prune
prune-i:
	@clear
	@echo "${DANGER}----------------!!! DANGER !!!----------------"
	@echo "Будет выполнена команда <${INFO}docker images prune${DANGER}>."
	@echo "${DANGER}Будут удалены все зависшие образы"
	@read -p "${WARNING}Вы точно уверены, что хотите продолжить? [yes/n]: ${RESET}" TAG \
	&& if [ "_$${TAG}" != "_yes" ]; then echo "Nothing happened"; exit 1 ; fi
	$(call log, Remove all unused images)
	docker images prune
prune-v:
	@clear
	@echo "${DANGER}----------------!!! DANGER !!!----------------"
	@echo "Будет выполнена команда <${INFO}docker volume prune${DANGER}>."
	@echo "${DANGER}Будут удалены все не используемые тома"
	@read -p "${WARNING}Вы точно уверены, что хотите продолжить? [yes/n]: ${RESET}" TAG \
	&& if [ "_$${TAG}" != "_yes" ]; then echo "Nothing happened"; exit 1 ; fi
	$(call log, Remove all unused volumes)
	docker volume prune
prune-n:
	@clear
	@echo "${DANGER}----------------!!! DANGER !!!----------------"
	@echo "Будет выполнена команда <${INFO}docker network prune${DANGER}>."
	@echo "${DANGER}Будут удалены не используемые сети"
	@read -p "${WARNING}Вы точно уверены, что хотите продолжить? [yes/n]: ${RESET}" TAG \
	&& if [ "_$${TAG}" != "_yes" ]; then echo "Nothing happened"; exit 1 ; fi
	$(call log, Remove all unused networks)
	docker network prune


# show docker-compose configuration
.PHONY: config
config:
	$(call log, Docker-compose configuration)
	$(call run_docker_compose, ${COMPOSE_PROFILE_DEFAULT} config)
