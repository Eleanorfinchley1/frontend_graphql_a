#!/usr/bin/env bash
docker-compose run --service-ports --rm elixir-app $@
docker-compose run --service-ports --rm elixir-app chown -R $(id -u):$(id -g) .