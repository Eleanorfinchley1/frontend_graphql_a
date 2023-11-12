SHELL=bash
MAKEFILE_DIR=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
IMAGE_TAG=billbored-agora_token_generator

build_local:
	cd $(MAKEFILE_DIR) && go build -o agora_token_generator main.go

build_target:
	cd $(MAKEFILE_DIR) && docker build -t $(IMAGE_TAG) .
	$(eval CONTAINER_ID=$(shell docker run -it --rm --detach --entrypoint /bin/bash $(IMAGE_TAG)))
	-docker cp $(CONTAINER_ID):/go/src/agora_token_generator/agora_token_generator $(MAKEFILE_DIR)/../../priv/bin/agora_token_generator
	docker stop $(CONTAINER_ID)
