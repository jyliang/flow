# Pack.mk — shared make targets that any pack's own Makefile can `include`.
# Imported by: ~/.flow/packs/<name>/Makefile (optional, for users who want
# pack-local make targets that mirror the runtime's pack-* verbs).
#
# Variables expected in the including Makefile (or env):
#   PACK_NAME — pack name (defaults to basename of CWD)

PACK_NAME ?= $(notdir $(CURDIR))
FLOW_HOME ?= $(HOME)/.flow
RUNTIME_PATH := $(shell cat $(FLOW_HOME)/runtime-path 2>/dev/null)

.PHONY: pack-help pack-status pack-branch pack-pr pack-pull pack-push

pack-help:
	@echo "Pack-local targets (this pack: $(PACK_NAME)):"
	@echo "  make pack-status              - git status"
	@echo "  make pack-branch BRANCH=...   - cut an edit branch"
	@echo "  make pack-pr TITLE=... BODY=...   - open PR for current branch"
	@echo "  make pack-pull / pack-push    - sync with remote"

pack-status:
	@bash $(RUNTIME_PATH)/scripts/pack-git.sh status $(PACK_NAME)

pack-branch:
	@bash $(RUNTIME_PATH)/scripts/pack-branch.sh $(PACK_NAME) $(BRANCH)

pack-pr:
	@bash $(RUNTIME_PATH)/scripts/pack-pr.sh $(PACK_NAME) "$(TITLE)" "$(BODY)"

pack-pull:
	@bash $(RUNTIME_PATH)/scripts/pack-git.sh pull $(PACK_NAME)

pack-push:
	@bash $(RUNTIME_PATH)/scripts/pack-git.sh push $(PACK_NAME)
