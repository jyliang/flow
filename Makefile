SKILLS_DIR := $(HOME)/.claude/skills
COMMANDS_DIR := $(HOME)/.claude/commands
SKILL_DIRS := $(wildcard skills/*)
COMMAND_FILES := $(wildcard commands/*.md)

.PHONY: install help list

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

list: ## List all available skills
	@for dir in $(SKILL_DIRS); do \
		name=$$(basename $$dir); \
		desc=$$(grep '^  short-description:' $$dir/SKILL.md 2>/dev/null | sed 's/.*: //'); \
		if [ -z "$$desc" ]; then \
			desc=$$(grep '^description:' $$dir/SKILL.md 2>/dev/null | head -1 | sed 's/description: //'); \
		fi; \
		printf "  %-16s %s\n" "$$name" "$$desc"; \
	done

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'
