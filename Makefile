SKILLS_DIR := $(HOME)/.claude/skills
COMMANDS_DIR := $(HOME)/.claude/commands
SKILL_DIRS := $(wildcard skills/*)
COMMAND_FILES := $(wildcard commands/*.md)

LINT_DOC_PATHS := README.md skills commands

.PHONY: install help list lint-docs

install: ## Install all skills and slash commands into ~/.claude/
	@mkdir -p $(SKILLS_DIR)
	@for dir in $(SKILL_DIRS); do \
		name=$$(basename $$dir); \
		echo "Installing skill $$name..."; \
		rm -rf $(SKILLS_DIR)/$$name; \
		cp -r $$dir $(SKILLS_DIR)/$$name; \
	done
	@mkdir -p $(COMMANDS_DIR)
	@for f in $(COMMAND_FILES); do \
		name=$$(basename $$f); \
		echo "Installing command $$name..."; \
		rm -f $(COMMANDS_DIR)/$$name; \
		cp $$f $(COMMANDS_DIR)/$$name; \
	done
	@echo ""
	@echo "Installed $$(echo $(SKILL_DIRS) | wc -w | tr -d ' ') skills to $(SKILLS_DIR)"
	@echo "Installed $$(echo $(COMMAND_FILES) | wc -w | tr -d ' ') commands to $(COMMANDS_DIR)"

list: ## List all available skills and commands
	@echo "Skills:"
	@for dir in $(SKILL_DIRS); do \
		name=$$(basename $$dir); \
		desc=$$(grep '^  short-description:' $$dir/SKILL.md 2>/dev/null | sed 's/.*: //'); \
		if [ -z "$$desc" ]; then \
			desc=$$(grep '^description:' $$dir/SKILL.md 2>/dev/null | head -1 | sed 's/description: //'); \
		fi; \
		printf "  %-16s %s\n" "$$name" "$$desc"; \
	done
	@echo ""
	@echo "Commands:"
	@for f in $(COMMAND_FILES); do \
		name=$$(basename $$f .md); \
		desc=$$(grep '^description:' $$f 2>/dev/null | head -1 | sed 's/description: //'); \
		printf "  /%-15s %s\n" "$$name" "$$desc"; \
	done

lint-docs: ## Check markdown docs for style-guide regressions (untagged fences, decimal steps)
	@bad=0; \
	files=$$(find $(LINT_DOC_PATHS) -type f -name '*.md' 2>/dev/null); \
	echo "Linting $$(echo $$files | wc -w | tr -d ' ') markdown files..."; \
	echo ""; \
	echo "==> Untagged code fences (principle 7)"; \
	for f in $$files; do \
		awk -v file="$$f" 'BEGIN { fence="" } /^(```+|~~~+)/ { match($$0, /^(`+|~+)/); marker=substr($$0, RSTART, RLENGTH); rest=substr($$0, RLENGTH+1); if (fence=="") { if (marker ~ /^`+$$/ && rest=="") { print file ":" NR ": untagged code fence"; bad=1 } fence=marker } else if (marker==fence && rest=="") { fence="" } } END { exit bad }' "$$f" || bad=1; \
	done; \
	echo "==> Decimal step numbers (principle 3)"; \
	if grep -rnE '^###? Step [0-9]+\.[0-9]' $(LINT_DOC_PATHS) 2>/dev/null; then bad=1; fi; \
	echo "==> TODO/FIXME/XXX leftovers"; \
	if grep -rnE '\b(TODO|FIXME|XXX)\b' $(LINT_DOC_PATHS) 2>/dev/null; then bad=1; fi; \
	echo ""; \
	if [ $$bad -eq 0 ]; then echo "docs lint: clean"; else echo "docs lint: FAILED"; exit 1; fi

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'
