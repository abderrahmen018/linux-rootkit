# Makefile for Resident Application Project
# Build system for PCB Monitor with installation scripts

# Compiler and flags
CC = gcc
CFLAGS = -Wall -Wextra -O2
LDFLAGS = -ldl

# Directories
SRC_DIR = src
BUILD_DIR = build
SCRIPTS_DIR = scripts
DIST_DIR = dist

# Source files
LIB_SRC = $(SRC_DIR)/hiderlib.c
APP_SRC = $(SRC_DIR)/hiddenprocess.c

# Output files
LIB_OUT = $(BUILD_DIR)/hiderlib.so
APP_OUT = $(BUILD_DIR)/hiddenprocess

# Distribution package name
DIST_PACKAGE = $(DIST_DIR)/hiddenprocess-package

# Colors for output (works on Linux/WSL)
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[1;33m
BLUE = \033[0;34m
NC = \033[0m # No Color

.PHONY: all clean build install uninstall dist help setup lib app

# Default target
all: setup build

# Help target
help:
	@echo "════════════════════════════════════════════════════════════"
	@echo "  Resident Application - Makefile Help"
	@echo "════════════════════════════════════════════════════════════"
	@echo ""
	@echo "Available targets:"
	@echo "  make all          - Setup directories and build all components"
	@echo "  make build        - Build all components (library and app)"
	@echo "  make lib          - Build only the shared library"
	@echo "  make app          - Build only the application"
	@echo "  make clean        - Remove build artifacts"
	@echo "  make dist         - Create distribution package"
	@echo "  make install      - Install using systemd service"
	@echo "  make uninstall    - Uninstall systemd version"
	@echo "  make help         - Show this help message"
	@echo ""
	@echo "Build directory: $(BUILD_DIR)/"
	@echo "Distribution directory: $(DIST_DIR)/"
	@echo ""

# Setup directories
setup:
	@echo "$(BLUE)Setting up build directories...$(NC)"
	@mkdir -p $(BUILD_DIR)
	@mkdir -p $(DIST_DIR)
	@echo "$(GREEN)✓ Directories created$(NC)"

# Build all components
build: setup lib app
	@echo ""
	@echo "$(BLUE)════════════════════════════════════════════════════════════$(NC)"
	@echo "$(GREEN)✓ Build Complete!$(NC)"
	@echo "$(BLUE)════════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo "Built files:"
	@echo "  $(GREEN)•$(NC) $(LIB_OUT)"
	@echo "  $(GREEN)•$(NC) $(APP_OUT)"
	@echo ""

# Build shared library
lib: $(LIB_OUT)

$(LIB_OUT): $(LIB_SRC)
	@echo "$(YELLOW)Building shared library...$(NC)"
	$(CC) $(CFLAGS) -shared -fPIC $(LDFLAGS) -o $(LIB_OUT) $(LIB_SRC)
	@echo "$(GREEN)✓ Built: $(LIB_OUT)$(NC)"

# Build application
app: $(APP_OUT)

$(APP_OUT): $(APP_SRC)
	@echo "$(YELLOW)Building application...$(NC)"
	$(CC) $(CFLAGS) -o $(APP_OUT) $(APP_SRC)
	@chmod +x $(APP_OUT)
	@echo "$(GREEN)✓ Built: $(APP_OUT)$(NC)"

# Create distribution package
dist: build
	@echo "$(BLUE)Creating distribution package...$(NC)"
	@mkdir -p $(DIST_PACKAGE)
	@cp $(LIB_OUT) $(DIST_PACKAGE)/
	@cp $(APP_OUT) $(DIST_PACKAGE)/
	@cp $(SCRIPTS_DIR)/install.sh $(DIST_PACKAGE)/
	@cp $(SCRIPTS_DIR)/uninstall.sh $(DIST_PACKAGE)/
	@chmod +x $(DIST_PACKAGE)/*.sh
	@echo "$(GREEN)✓ Distribution package created at: $(DIST_PACKAGE)/$(NC)"
	@echo ""
	@echo "Package contents:"
	@ls -lh $(DIST_PACKAGE)/
	@echo ""
	@echo "To create a zip archive:"
	@echo "  cd $(DIST_DIR) && zip -r hiddenprocess-package.zip hiddenprocess-package/"

# Install using systemd service
install: build
	@echo "$(BLUE)Installing with systemd service...$(NC)"
	@if [ "$$(id -u)" -ne 0 ]; then \
		echo "$(RED)Error: Installation requires root privileges$(NC)"; \
		echo "Please run: sudo make install"; \
		exit 1; \
	fi
	@chmod +x $(SCRIPTS_DIR)/install.sh
	@cd $(BUILD_DIR) && bash ../$(SCRIPTS_DIR)/install.sh

# Uninstall systemd version
uninstall:
	@echo "$(BLUE)Uninstalling systemd version...$(NC)"
	@if [ "$$(id -u)" -ne 0 ]; then \
		echo "$(RED)Error: Uninstallation requires root privileges$(NC)"; \
		echo "Please run: sudo make uninstall"; \
		exit 1; \
	fi
	@chmod +x $(SCRIPTS_DIR)/uninstall.sh
	@bash $(SCRIPTS_DIR)/uninstall.sh

# Clean build artifacts
clean:
	@echo "$(YELLOW)Cleaning build artifacts...$(NC)"
	@rm -rf $(BUILD_DIR)
	@rm -rf $(DIST_DIR)
	@echo "$(GREEN)✓ Clean complete$(NC)"

# Rebuild everything
rebuild: clean all
