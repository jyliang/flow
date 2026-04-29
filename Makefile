# Flow runtime Makefile — user-facing CLI for kernel install + cell management.
# All cell-* targets operate on the active cell (~/.flow/active-cell) by default;
# pass NAME=<cell> to address a specific cell.

RUNTIME_ROOT := $(abspath $(dir $(firstword $(MAKEFILE_LIST))))
FLOW_HOME := $(HOME)/.flow
CLAUDE_DIR := $(HOME)/.claude
SKILLS_DIR := $(CLAUDE_DIR)/skills
COMMANDS_DIR := $(CLAUDE_DIR)/commands

KERNEL_SKILLS := $(wildcard $(RUNTIME_ROOT)/skills/*)
KERNEL_COMMANDS := $(wildcard $(RUNTIME_ROOT)/commands/*.md)

LINT_DOC_PATHS := README.md skills commands cells

.PHONY: help install doctor list lint-docs \
	cell-init cell-new cell-list cell-use cell-rm \
	cell-status cell-link-remote cell-pull cell-push cell-branch cell-pr

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'

install: ## Install kernel into ~/.claude/, provision ~/.flow/
	@bash $(RUNTIME_ROOT)/scripts/install.sh

doctor: ## Sanity check the install
	@bash $(RUNTIME_ROOT)/scripts/doctor.sh

list: ## List installed kernel skills and slash commands
	@echo "Kernel skills:"
	@for dir in $(KERNEL_SKILLS); do \
		name=$$(basename $$dir); \
		desc=$$(grep '^  short-description:' $$dir/SKILL.md 2>/dev/null | sed 's/.*: //'); \
		printf "  %-12s %s\n" "$$name" "$$desc"; \
	done
	@echo ""
	@echo "Slash commands:"
	@for f in $(KERNEL_COMMANDS); do \
		name=$$(basename $$f .md); \
		desc=$$(grep '^description:' $$f 2>/dev/null | head -1 | sed 's/description: //'); \
		printf "  /%-11s %s\n" "$$name" "$$desc"; \
	done

# ----- Cell lifecycle -----

cell-init: ## Clone a starter into ~/.flow/cells/<NAME>/ (vars: STARTER, NAME)
	@bash $(RUNTIME_ROOT)/scripts/cell-init.sh "$(STARTER)" "$(NAME)"

cell-new: ## Empty cell scaffold (var: NAME)
	@bash $(RUNTIME_ROOT)/scripts/cell-init.sh "" "$(NAME)"

cell-list: ## Show installed cells, mark active
	@bash $(RUNTIME_ROOT)/scripts/cell-list.sh

cell-use: ## Switch active cell (var: NAME)
	@bash $(RUNTIME_ROOT)/scripts/cell-use.sh "$(NAME)"

cell-rm: ## Remove a cell (var: NAME)
	@bash $(RUNTIME_ROOT)/scripts/cell-rm.sh "$(NAME)"

# ----- Per-cell git operations (default: active cell; override with NAME=) -----

cell-status: ## git status of the cell
	@bash $(RUNTIME_ROOT)/scripts/cell-git.sh status "$(NAME)"

cell-link-remote: ## Add origin to the cell (vars: URL, optional NAME)
	@bash $(RUNTIME_ROOT)/scripts/cell-git.sh link-remote "$(NAME)" "$(URL)"

cell-pull: ## git pull on the cell
	@bash $(RUNTIME_ROOT)/scripts/cell-git.sh pull "$(NAME)"

cell-push: ## git push on the cell
	@bash $(RUNTIME_ROOT)/scripts/cell-git.sh push "$(NAME)"

cell-branch: ## Cut a branch in the cell for an edit (vars: BRANCH, optional NAME)
	@bash $(RUNTIME_ROOT)/scripts/cell-branch.sh "$(NAME)" "$(BRANCH)"

cell-pr: ## Open a PR for current cell edits (vars: TITLE, BODY; optional NAME)
	@bash $(RUNTIME_ROOT)/scripts/cell-pr.sh "$(NAME)" "$(TITLE)" "$(BODY)"

# ----- Doc lint (preserved from v2) -----

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
