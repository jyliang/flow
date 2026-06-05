# Makefile — serve and check the project's docs.
# The founding doc (docs/founding/) is a `composite` doc-type: an HTML host
# plus markdown/Mermaid fragments loaded over HTTP. `make serve-docs` is the
# intended way to read it.

ROOT := $(abspath $(dir $(firstword $(MAKEFILE_LIST))))
PORT ?= 8731

.PHONY: help serve-docs open-docs lint-docs

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[35m%-14s\033[0m %s\n", $$1, $$2}'

serve-docs: ## Serve the composite docs over HTTP (set PORT to override 8731)
	@sh $(ROOT)/docs/serve.sh $(PORT)

open-docs: ## Open the founding doc in a browser (assumes serve-docs is running)
	@open "http://localhost:$(PORT)/founding/index.html" 2>/dev/null || \
		printf 'Open http://localhost:%s/founding/index.html\n' "$(PORT)"

lint-docs: ## Flag leftover TODO/FIXME in docs
	@bad=0; \
	echo "==> TODO/FIXME/XXX leftovers"; \
	if grep -rnE '\b(TODO|FIXME|XXX)\b' docs 2>/dev/null; then bad=1; fi; \
	if [ $$bad -eq 0 ]; then echo "docs lint: clean"; else echo "docs lint: FAILED"; exit 1; fi
