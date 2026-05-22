# Flow Makefile — install the `flow` CLI and check the doc-type catalog.
# Flow is a pipeline-builder: assemble a chain of (skill, doc-type) pairs and
# compile it into two skills. The CLI is bin/flow; the catalog is doc-types/.

ROOT := $(abspath $(dir $(firstword $(MAKEFILE_LIST))))
LINT_DOC_PATHS := README.md doc-types templates

.PHONY: help install uninstall doctor list lint-docs

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

install: ## Put the flow CLI on PATH; clear stale plugin registration
	@bash $(ROOT)/scripts/install.sh

uninstall: ## Remove the flow CLI symlink from PATH
	@for d in "$$HOME/.local/bin" /opt/homebrew/bin /usr/local/bin "$$HOME/bin"; do \
		if [ -L "$$d/flow" ] && [ "$$(readlink "$$d/flow")" = "$(ROOT)/bin/flow" ]; then \
			rm -f "$$d/flow"; echo "removed $$d/flow"; fi; \
	done

doctor: ## Sanity check the install
	@bash $(ROOT)/scripts/doctor.sh

list: ## List the doc-type catalog
	@$(ROOT)/bin/flow list --doc-types

lint-docs: ## Check markdown docs for style-guide regressions
	@bad=0; \
	files=$$(find $(LINT_DOC_PATHS) -type f -name '*.md' 2>/dev/null); \
	echo "Linting $$(echo $$files | wc -w | tr -d ' ') markdown files..."; \
	echo ""; \
	echo "==> Untagged code fences"; \
	for f in $$files; do \
		awk -v file="$$f" 'BEGIN { fence="" } /^(```+|~~~+)/ { match($$0, /^(`+|~+)/); marker=substr($$0, RSTART, RLENGTH); rest=substr($$0, RLENGTH+1); if (fence=="") { if (marker ~ /^`+$$/ && rest=="") { print file ":" NR ": untagged code fence"; bad=1 } fence=marker } else if (marker==fence && rest=="") { fence="" } } END { exit bad }' "$$f" || bad=1; \
	done; \
	echo "==> Decimal step numbers"; \
	if grep -rnE '^###? Step [0-9]+\.[0-9]' $(LINT_DOC_PATHS) 2>/dev/null; then bad=1; fi; \
	echo "==> TODO/FIXME/XXX leftovers"; \
	if grep -rnE '\b(TODO|FIXME|XXX)\b' $(LINT_DOC_PATHS) 2>/dev/null; then bad=1; fi; \
	echo ""; \
	if [ $$bad -eq 0 ]; then echo "docs lint: clean"; else echo "docs lint: FAILED"; exit 1; fi
