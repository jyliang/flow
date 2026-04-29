# Cell.mk — shared make targets that any cell's own Makefile can `include`.
# Imported by: ~/.flow/cells/<name>/Makefile (optional, for users who want
# cell-local make targets that mirror the runtime's cell-* verbs).
#
# Variables expected in the including Makefile (or env):
#   CELL_NAME — cell name (defaults to basename of CWD)

CELL_NAME ?= $(notdir $(CURDIR))
FLOW_HOME ?= $(HOME)/.flow
RUNTIME_PATH := $(shell cat $(FLOW_HOME)/runtime-path 2>/dev/null)

.PHONY: cell-help cell-status cell-branch cell-pr cell-pull cell-push

cell-help:
	@echo "Cell-local targets (this cell: $(CELL_NAME)):"
	@echo "  make cell-status              - git status"
	@echo "  make cell-branch BRANCH=...   - cut an edit branch"
	@echo "  make cell-pr TITLE=... BODY=...   - open PR for current branch"
	@echo "  make cell-pull / cell-push    - sync with remote"

cell-status:
	@bash $(RUNTIME_PATH)/scripts/cell-git.sh status $(CELL_NAME)

cell-branch:
	@bash $(RUNTIME_PATH)/scripts/cell-branch.sh $(CELL_NAME) $(BRANCH)

cell-pr:
	@bash $(RUNTIME_PATH)/scripts/cell-pr.sh $(CELL_NAME) "$(TITLE)" "$(BODY)"

cell-pull:
	@bash $(RUNTIME_PATH)/scripts/cell-git.sh pull $(CELL_NAME)

cell-push:
	@bash $(RUNTIME_PATH)/scripts/cell-git.sh push $(CELL_NAME)
