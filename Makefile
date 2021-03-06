# Copyright SecureKey Technologies Inc.
#
# SPDX-License-Identifier: Apache-2.0

GO_CMD ?= go
ISSUER_REST_PATH=cmd/issuer-rest
RP_REST_PATH=cmd/rp-rest
STRAPI_DEMO_PATH=cmd/strapi-demo

DOCKER_OUTPUT_NS         ?= docker.pkg.github.com
# Namespace for the issuer image
ISSUER_REST_IMAGE_NAME   ?= trustbloc/edge-sandbox/issuer-rest
# Namespace for the ro image
RP_REST_IMAGE_NAME   ?= trustbloc/edge-sandbox/rp-rest

# Tool commands (overridable)
ALPINE_VER ?= 3.10
GO_VER     ?= 1.13.1

.PHONY: all
all: checks unit-test

.PHONY: checks
checks: license lint

.PHONY: lint
lint:
	@scripts/check_lint.sh

.PHONY: license
license:
	@scripts/check_license.sh

unit-test:
	@scripts/check_unit.sh


demo-start: clean issuer-rest-docker rp-rest-docker generate-test-keys
	@scripts/sandbox_start.sh

demo-stop:
	@scripts/sandbox_stop.sh

hydra-test-app:
	@scripts/hydra_test_app.sh

issuer-rest:
	@echo "Building issuer-rest"
	@mkdir -p ./build/bin/issuer
	@cp -r ${ISSUER_REST_PATH}/static ./build/bin/issuer
	@cd ${ISSUER_REST_PATH} && go build -o ../../build/bin/issuer/issuer-rest main.go

rp-rest:
	@echo "Building rp-rest"
	@mkdir -p ./build/bin/rp
	@cp -r ${RP_REST_PATH}/static ./build/bin/rp
	@cd ${RP_REST_PATH} && go build -o ../../build/bin/rp/rp-rest main.go

strapi-build:
	@echo "Building strapi demo"
	@mkdir -p ./build/bin
	@cd ${STRAPI_DEMO_PATH} && go build -o ../../build/bin/strapi-demo main.go

strapi-setup: strapi-build
	@scripts/strapi-setup.sh


.PHONY: issuer-rest-docker
issuer-rest-docker:
	@echo "Building issuer rest docker image"
	@docker build -f ./images/issuer-rest/Dockerfile --no-cache -t $(DOCKER_OUTPUT_NS)/$(ISSUER_REST_IMAGE_NAME):latest \
	--build-arg GO_VER=$(GO_VER) \
	--build-arg ALPINE_VER=$(ALPINE_VER) .

.PHONY: rp-rest-docker
rp-rest-docker:
	@echo "Building rp rest docker image"
	@docker build -f ./images/rp-rest/Dockerfile --no-cache -t $(DOCKER_OUTPUT_NS)/$(RP_REST_IMAGE_NAME):latest \
	--build-arg GO_VER=$(GO_VER) \
	--build-arg ALPINE_VER=$(ALPINE_VER) .

.PHONY: generate-test-keys
generate-test-keys: clean
	@mkdir -p -p test/bdd/fixtures/keys/tls
	@docker run -i --rm \
		-v $(abspath .):/opt/workspace/edge-sandbox \
		--entrypoint "/opt/workspace/edge-sandbox/scripts/generate_test_keys.sh" \
		frapsoft/openssl

.PHONY: clean
clean: clean-build

.PHONY: clean-build
clean-build:
	@rm -Rf ./build
	@rm -Rf ./test/bdd/fixtures/keys
