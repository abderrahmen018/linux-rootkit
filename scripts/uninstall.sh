#!/bin/bash

# Uninstallation script for Resident Application
# Must be run as root (sudo)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}    Resident Application - Uninstaller${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This uninstaller must be run as root (use sudo)${NC}"
    exit 1
fi

# Configuration
SO_FILENAME="hiderlib.so"
EXEC_FILENAME="hiddenprocess"
INSTALL_PATH="/opt/hiddenprocess"
SERVICE_NAME="hiddenprocess"
LD_SO_PRELOAD="/etc/ld.so.preload"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

echo -e "${YELLOW}⚠ This will remove the Resident Application service from your system${NC}"
echo ""

# Stop the service
echo -e "${BLUE}Stopping systemd service...${NC}"
if systemctl is-active --quiet "$SERVICE_NAME.service"; then
    systemctl stop "$SERVICE_NAME.service"
    echo -e "${GREEN}✓ Service stopped${NC}"
else
    echo -e "${YELLOW}⚠ Service is not running${NC}"
fi
echo ""

# Disable the service
echo -e "${BLUE}Disabling systemd service...${NC}"
if systemctl is-enabled --quiet "$SERVICE_NAME.service" 2>/dev/null; then
    systemctl disable "$SERVICE_NAME.service"
    echo -e "${GREEN}✓ Service disabled${NC}"
else
    echo -e "${YELLOW}⚠ Service is not enabled${NC}"
fi
echo ""

# Remove service file
echo -e "${BLUE}Removing service file...${NC}"
if [ -f "$SERVICE_FILE" ]; then
    rm -f "$SERVICE_FILE"
    echo -e "${GREEN}✓ Removed: $SERVICE_FILE${NC}"
else
    echo -e "${YELLOW}⚠ Service file not found${NC}"
fi
echo ""

# Reload systemd daemon
echo -e "${BLUE}Reloading systemd daemon...${NC}"
systemctl daemon-reload
echo -e "${GREEN}✓ Systemd daemon reloaded${NC}"
echo ""

# Reset failed units (cleanup)
systemctl reset-failed 2>/dev/null

# Remove from ld.so.preload
echo -e "${BLUE}Removing from ld.so.preload...${NC}"
SO_PATH="$INSTALL_PATH/$SO_FILENAME"
if [ -f "$LD_SO_PRELOAD" ]; then
    if grep -Fxq "$SO_PATH" "$LD_SO_PRELOAD"; then
        # Remove the line containing the path
        sed -i "\|^$SO_PATH$|d" "$LD_SO_PRELOAD"
        echo -e "${GREEN}✓ Removed $SO_PATH from $LD_SO_PRELOAD${NC}"
    else
        echo -e "${YELLOW}⚠ Path not found in $LD_SO_PRELOAD${NC}"
    fi
else
    echo -e "${YELLOW}⚠ $LD_SO_PRELOAD does not exist${NC}"
fi
echo ""

# Kill any remaining processes (backup, shouldn't be needed)
echo -e "${BLUE}Ensuring all processes are stopped...${NC}"
PIDS=$(pgrep -x "$EXEC_FILENAME")
if [ -n "$PIDS" ]; then
    kill $PIDS 2>/dev/null
    sleep 1
    # Force kill if still running
    PIDS=$(pgrep -x "$EXEC_FILENAME")
    if [ -n "$PIDS" ]; then
        kill -9 $PIDS 2>/dev/null
    fi
    echo -e "${GREEN}✓ Stopped remaining processes${NC}"
else
    echo -e "${YELLOW}⚠ No running processes found${NC}"
fi
echo ""

# Remove installation directory
echo -e "${BLUE}Removing installation files...${NC}"
if [ -d "$INSTALL_PATH" ]; then
    rm -rf "$INSTALL_PATH"
    echo -e "${GREEN}✓ Removed: $INSTALL_PATH${NC}"
else
    echo -e "${YELLOW}⚠ Installation directory not found${NC}"
fi
echo ""

# Remove log file
echo -e "${BLUE}Removing log files...${NC}"
LOG_FILE="/root/process.txt"
if [ -f "$LOG_FILE" ]; then
    rm -f "$LOG_FILE"
    echo -e "${GREEN}✓ Removed: $LOG_FILE${NC}"
else
    echo -e "${YELLOW}⚠ Log file not found${NC}"
fi
echo ""

# Clean systemd journal logs (optional)
echo -e "${BLUE}Cleaning systemd journal logs...${NC}"
journalctl --vacuum-time=1s --unit="$SERVICE_NAME.service" 2>/dev/null
echo -e "${GREEN}✓ Journal logs cleaned${NC}"
echo ""

# Summary
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Uninstallation Complete!${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Removed components:"
echo -e "  ${GREEN}•${NC} Systemd service:        $SERVICE_FILE"
echo -e "  ${GREEN}•${NC} Installation directory: $INSTALL_PATH"
echo -e "  ${GREEN}•${NC} LD preload entry:       $LD_SO_PRELOAD"
echo -e "  ${GREEN}•${NC} Log file:               $LOG_FILE"
echo -e "  ${GREEN}•${NC} Service status:         Stopped and disabled"
echo -e "  ${GREEN}•${NC} Journal logs:           Cleaned"
echo ""
echo "Verification commands:"
echo -e "  ${BLUE}systemctl status $SERVICE_NAME${NC} (should show 'Unit not found')"
echo -e "  ${BLUE}pgrep -x $EXEC_FILENAME${NC} (should return nothing)"
echo ""
echo -e "${YELLOW}Note: You may want to reboot to ensure all changes take effect${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
