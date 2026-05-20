.PHONY: init build-image build-widget up down logs update help

LANG       ?= go
VERSION    ?= v0.1.0
COMPONENT  ?=

## init: clone all submodules
init:
	git submodule update --init --recursive

## build-image: build Docker image for a language pack
##   make build-image LANG=go
build-image:
	@echo "Building image for pack: $(LANG)"
	cp -r vim-configs/$(LANG) docker-images/$(LANG)/vim-configs/$(LANG)
	docker build \
		-t goalgo/tps-$(LANG):$(VERSION) \
		-f docker-images/$(LANG)/Dockerfile \
		docker-images/$(LANG)
	rm -rf docker-images/$(LANG)/vim-configs

## build-widget: bundle tps-widget JS
build-widget:
	cd tps-widget && npm ci && npm run build

## up: start the full local stack
up:
	EXERCISES_HOST_PATH=$$(pwd)/exercises docker compose up --build -d
	@echo "Gateway:  http://localhost:8080"
	@echo "Sessions: http://localhost:8081"
	@echo "Pool Go:  http://localhost:8082"

## down: stop the local stack
down:
	docker compose down

## logs: follow logs of all services
logs:
	docker compose logs -f

## update: update a component version in platform.toml
##   make update COMPONENT=docker-images/go VERSION=v1.1.0
update:
	@if [ -z "$(COMPONENT)" ]; then echo "Usage: make update COMPONENT=... VERSION=..."; exit 1; fi
	sed -i 's|"$(COMPONENT)" = ".*"|"$(COMPONENT)" = "$(VERSION)"|' platform.toml
	@echo "Updated $(COMPONENT) → $(VERSION) in platform.toml"

## help: show this help
help:
	@grep -E '^## ' Makefile | sed 's/^## //'
