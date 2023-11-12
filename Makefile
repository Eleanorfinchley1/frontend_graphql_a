.PHONY: help

VERSION ?= `grep 'version' mix.exs | sed -e 's/ //g' -e 's/version://' -e 's/[",]//g'`
IMAGE_NAME ?= billbored
PWD ?= `pwd`

help:
	@echo "$(IMAGE_NAME):$(VERSION)"
	@perl -nle'print $& if m{^[a-zA-Z_-]+:.*?## .*$$}' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

db_setup: ## Migrate the database
	mix ecto.setup
	MIX_ENV=test mix ecto.setup

check: ## Run checks
	mix format --check-formatted
	mix credo -a
	mix dialyzer
	mix test

build_release: ## Build a release of the application
	docker run -v $(PWD):/opt/build -v $(PWD)/.cache/_build:/opt/build/_build -v $(PWD)/.cache/deps:/opt/build/deps --rm -it semaphoreci/elixir:1.9-node /opt/build/bin/build

deploy: ## Deploy to the dev gcp vm
	gcloud compute scp rel/artifacts/$(IMAGE_NAME)-$(VERSION).tar.gz dev:~/
	gcloud compute ssh dev -- "sudo tar -xzf $(IMAGE_NAME)-$(VERSION).tar.gz -C /opt/billbored"
	gcloud compute ssh dev -- "sudo systemctl restart billbored"
