IMAGE ?= openbao-custom
TAG   ?= latest

.PHONY: build run

build:
	docker build -f docker/Dockerfile -t $(IMAGE):$(TAG) .

run: build
	docker compose up -d

openbao-inizilise: run
	docker exec -it openbao bao operator init

#Wichtig! speichern von Unseal Keys und den Root Token

openbao-entsperren: run
	docker exec -it openbao bao operator unseal

#verfügbar unter http://localhost:8200 im Browser
openbao-login: run
	docker exec -it openbao bao login