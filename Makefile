##@ General

# The help target prints out all targets with their descriptions organized
# beneath their categories. The categories are represented by '##@' and the
# target descriptions by '##'. The awk commands is responsible for reading the
# entire set of makefiles included in this invocation, looking for lines of the
# file as xyz: ## something, and then pretty-format the target and help. Then,
# if there's a line with ##@ something, that gets pretty-printed as a category.
# More info on the usage of ANSI control characters for terminal formatting:
# https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_parameters
# More info on the awk command:
# http://linuxcommand.org/lc3_adv_awk.php

.PHONY: help
help: ## Display this help.
        @awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

IMAGE ?= ghcr.io/githedgehog/hhdocs:latest
RUN = docker run --rm -v ${PWD}:/docs -p 8000:8000 $(IMAGE)
RUN_IT = docker run --rm -it -v ${PWD}:/docs -p 8000:8000 $(IMAGE)


.PHONY: all
all: build

.PHONY: docker
docker: ## Pull mkdocs docker image.
	docker pull -q $(IMAGE)

CMD ?= mkdocs

.PHONY: run
run: docker ## Run a command in the mkdocs docker image.
	$(RUN_IT) $(CMD)

.PHONY: build
build: docker ## Build the documentation.
	$(RUN) mkdocs build

.PHONY: serve
serve: docker ## Serve the documentation.
	$(RUN_IT) mkdocs serve -a 0.0.0.0:8000

.PHONY: serve-versioned
serve-versioned: docker ## Serve versioned documentation with mike.
	$(RUN_IT) mike serve -a 0.0.0.0:8000

RELEASE ?= dev
ALIAS ?= master

.PHONY: deploy
deploy: docker ## Deploy documentation version with mike.
	$(RUN) mike deploy -b publish -u $(RELEASE) $(ALIAS)

# TODO we need to "deploy dev" in master and "deploy -u alpha-x latest" in release/alpha-x branches