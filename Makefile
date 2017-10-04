# Docker
DOCKER_CMD = docker
DOCKER_BUILD = $(DOCKER_CMD) build
DOCKER_TAG ?= $(DOCKER_CMD) tag
DOCKER_PUSH ?= $(DOCKER_CMD) push

# Docker image tag
GIT_COMMIT=$(shell git rev-parse HEAD | cut -c1-7)
GIT_DIRTY=$(shell test -n "`git status --porcelain`" && echo "-dirty" || true)
DEV_PREFIX := dev
VERSION ?= $(DEV_PREFIX)-$(GIT_COMMIT)$(GIT_DIRTY)

# escape_docker_tag escape colon char to allow use a docker tag as rule
define escape_docker_tag
$(subst :,--,$(1))
endef

# unescape_docker_tag an escaped docker tag to be use in a docker command
define unescape_docker_tag
$(subst --,:,$(1))
endef

# if TRAVIS_TAG defined DOCKER_VERSION is overrided
ifneq ($(TRAVIS_TAG), )
    VERSION := $(TRAVIS_TAG)
endif

# if we are not in master, and it's not a tag the push is disabled
ifneq ($(TRAVIS_BRANCH), master)
	ifeq ($(TRAVIS_TAG), )
        pushdisabled = "push disabled for non-master branches"
	endif
endif

# if this is a pull request, the push is disabled
ifneq ($(TRAVIS_PULL_REQUEST), false)
        pushdisabled = "push disabled for pull-requests"
endif

DOCKER_IMAGE ?= src-d/spark-api-jupyter
DOCKER_IMAGE_VERSIONED ?= $(call escape_docker_tag,$(DOCKER_IMAGE):$(VERSION))

# Rules
all: clean build

clean:
	./sbt clean

build:
	./sbt assembly

docker-build: build
	$(DOCKER_BUILD) -t $(call unescape_docker_tag,$(DOCKER_IMAGE_VERSIONED)) .

push: docker-build
	$(if $(pushdisabled),$(error $(pushdisabled)))

	@if [ "$$DOCKER_USERNAME" != "" ]; then \
		$(DOCKER_CMD) login -u="$$DOCKER_USERNAME" -p="$$DOCKER_PASSWORD"; \
	fi;

	$(DOCKER_PUSH) $(call unescape_docker_tag,$(DOCKER_IMAGE_VERSIONED))
	@if [ "$$TRAVIS_TAG" != "" ]; then \
		$(DOCKER_TAG) $(call unescape_docker_tag,$(DOCKER_IMAGE_VERSIONED)) \
			$(call unescape_docker_tag,$(DOCKER_IMAGE)):latest; \
		$(DOCKER_PUSH) $(call unescape_docker_tag,$(DOCKER_IMAGE):latest); \
	fi;

