DOCKER = docker
IMAGE = lxzh/aosp:1.0

aosp: Dockerfile
	$(DOCKER) build -t $(IMAGE) .

all: aosp

.PHONY: all
