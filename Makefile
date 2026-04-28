# Flow runtime Makefile — user-facing CLI for kernel install + pack management.
# All pack-* targets operate on the active pack (~/.flow/active-pack) by default;
# pass NAME=<pack> to address a specific pack.

RUNTIME_ROOT := $(abspath $(dir $(firstword $(MAKEFILE_LIST))))
FLOW_HOME := $(HOME)/.flow
CLAUDE_DIR := $(HOME)/.claude
SKILLS_DIR := $(CLAUDE_DIR)/skills
COMMANDS_DIR := $(CLAUDE_DIR)/commands

KERNEL_SKILLS := $(wildcard $(RUNTIME_ROOT)/skills/*)
KERNEL_COMMANDS := $(wildcard $(RUNTIME_ROOT)/commands/*.md)

LINT_DOC_PATHS := README.md skills commands packs

.PHONY: help install doctor list lint-docs \
	pack-init pack-new pack-list pack-use pack-rm \
	pack-status pack-link-remote pack-pull pack-push pack-branch pack-pr

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

# ----- Pack lifecycle -----

pack-init: ## Clone a starter into ~/.flow/packs/<NAME>/ (vars: STARTER, NAME)
	@bash $(RUNTIME_ROOT)/scripts/pack-init.sh "$(STARTER)" "$(NAME)"

pack-new: ## Empty pack scaffold (var: NAME)
	@bash $(RUNTIME_ROOT)/scripts/pack-init.sh "" "$(NAME)"

pack-list: ## Show installed packs, mark active
	@bash $(RUNTIME_ROOT)/scripts/pack-list.sh

pack-use: ## Switch active pack (var: NAME)
	@bash $(RUNTIME_ROOT)/scripts/pack-use.sh "$(NAME)"

pack-rm: ## Remove a pack (var: NAME)
	@bash $(RUNTIME_ROOT)/scripts/pack-rm.sh "$(NAME)"

# ----- Per-pack git operations (default: active pack; override with NAME=) -----

pack-status: ## git status of the pack
	@bash $(RUNTIME_ROOT)/scripts/pack-git.sh status "$(NAME)"

pack-link-remote: ## Add origin to the pack (vars: URL, optional NAME)
	@bash $(RUNTIME_ROOT)/scripts/pack-git.sh link-remote "$(NAME)" "$(URL)"

pack-pull: ## git pull on the pack
	@bash $(RUNTIME_ROOT)/scripts/pack-git.sh pull "$(NAME)"

pack-push: ## git push on the pack
	@bash $(RUNTIME_ROOT)/scripts/pack-git.sh push "$(NAME)"

pack-branch: ## Cut a branch in the pack for an edit (vars: BRANCH, optional NAME)
	@bash $(RUNTIME_ROOT)/scripts/pack-branch.sh "$(NAME)" "$(BRANCH)"

pack-pr: ## Open a PR for current pack edits (vars: TITLE, BODY; optional NAME)
	@bash $(RUNTIME_ROOT)/scripts/pack-pr.sh "$(NAME)" "$(TITLE)" "$(BODY)"

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
