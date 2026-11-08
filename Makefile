.PHONY: run build test lint db-up db-down up down psql

run:
	go run ./cmd/pooler

build:
	go build -o bin/pooler ./cmd/pooler

test:
	go test -race ./...

lint:
	go vet ./...

db-up:
	docker compose up -d postgres

db-down:
	docker compose down

up:
	docker compose --profile full up -d --build

down:
	docker compose --profile full down

psql:
	psql "postgres://app:app@localhost:6432/app?sslmode=disable"
