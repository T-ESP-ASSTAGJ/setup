# Multi-Repository Setup Makefile
# Usage: make [target]

# Configuration
REPO_BASE_URL := git@github.com:T-ESP-ASSTAGJ
REPO1_NAME := api
REPO2_NAME := client
REPO3_NAME := infra

# Repository URLs
REPO1_URL := $(REPO_BASE_URL)/$(REPO1_NAME).git
REPO2_URL := $(REPO_BASE_URL)/$(REPO2_NAME).git
REPO3_URL := $(REPO_BASE_URL)/$(REPO3_NAME).git

# Default target
.PHONY: help
help:
	@echo "Available commands:"
	@echo "  setup     - Clone all repositories"
	@echo "  start-all - Start all projects"
	@echo "  clean     - Remove all cloned repositories"

# Clone all repositories
.PHONY: setup
setup: clone-repo1 clone-repo2 clone-repo3
	@echo "✅ All repositories cloned successfully"

# Clone individual repositories
.PHONY: clone-repo1
clone-repo1:
	@if [ ! -d "$(REPO1_NAME)" ]; then \
		echo "🔄 Cloning $(REPO1_NAME)..."; \
		git clone $(REPO1_URL) $(REPO1_NAME); \
	else \
		echo "📁 $(REPO1_NAME) already exists"; \
	fi

.PHONY: clone-repo2
clone-repo2:
	@if [ ! -d "$(REPO2_NAME)" ]; then \
		echo "🔄 Cloning $(REPO2_NAME)..."; \
		git clone $(REPO2_URL) $(REPO2_NAME); \
	else \
		echo "📁 $(REPO2_NAME) already exists"; \
	fi

.PHONY: clone-repo3
clone-repo3:
	@if [ ! -d "$(REPO3_NAME)" ]; then \
		echo "🔄 Cloning $(REPO3_NAME)..."; \
		git clone $(REPO3_URL) $(REPO3_NAME); \
	else \
		echo "📁 $(REPO3_NAME) already exists"; \
	fi

# Start all projects (assumes they're already cloned)
.PHONY: start-all
start-all:
	@echo "🚀 Starting all projects..."
	@if [ -d "$(REPO1_NAME)" ]; then \
		echo "Starting $(REPO1_NAME) in background..."; \
		cd $(REPO1_NAME) && (make start || npm start) & \
	fi
	@if [ -d "$(REPO2_NAME)" ]; then \
		echo "Starting $(REPO2_NAME) in background..."; \
		cd $(REPO2_NAME) && (make start || npm start) & \
	fi
	@if [ -d "$(REPO3_NAME)" ]; then \
		echo "Starting $(REPO3_NAME)..."; \
		cd $(REPO3_NAME) && (make start || npm start); \
	fi

# Clean up - remove all cloned repositories
.PHONY: clean
clean:
	@read -p "Are you sure you want to delete all repositories? [y/N] " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		rm -rf $(REPO1_NAME) $(REPO2_NAME) $(REPO3_NAME); \
		echo "🧹 All repositories removed"; \
	else \
		echo "❌ Clean cancelled"; \
	fi