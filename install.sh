#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

DIGIPI_USER=$USER
ENV_FILE="/home/${DIGIPI_USER}/localize.env"

echo "[*] Updating system"
sudo apt-get -qq update

echo "[*] Installing packages"
install_if_available() {
  local pkg="$1"
  if apt-cache show "$pkg" >/dev/null 2>&1; then
    sudo apt-get -qq install -y "$pkg"
  else
    echo "[!] Package not available: $pkg"
  fi
}

BASE_PACKAGES=(
  apache2
  ax25-tools
  cpufrequtils
  fldigi
  git
  libhamlib-utils
  js8call
  libjson-c-dev
  libwebsockets-dev
  build-essential
  cmake
  net-tools
  novnc
  openssh-client
  pat
  php
  libapache2-mod-php
  python3-adafruit-blinka
  qsstv
  rsync
  telnet
  tightvncserver
  ttyd
  wireless-tools
  wsjtx
  x11vnc
  xfonts-base
)

for pkg in "${BASE_PACKAGES[@]}"; do
  install_if_available "$pkg"
done

# vcgencmd package name varies on Pi OS releases
install_if_available "raspi-utils"

if ! command -v pat >/dev/null 2>&1 && command -v pat-winlink >/dev/null 2>&1; then
  echo "[*] Creating pat shim"
  sudo ln -sf "$(command -v pat-winlink)" /usr/local/bin/pat
fi

if ! command -v ttyd >/dev/null 2>&1; then
  echo "[*] ttyd not available from packages; building from source"
  sudo apt-get -qq install -y build-essential cmake git libjson-c-dev libwebsockets-dev
  rm -rf /tmp/ttyd
  git clone --quiet https://github.com/tsl0922/ttyd.git /tmp/ttyd
  (cd /tmp/ttyd && mkdir build && cd build && cmake .. && make && sudo make install)
fi

echo "[*] Preparing runtime log files"
sudo touch /run/direwolf.log /home/pi/direwolf.log
sudo chown pi:pi /run/direwolf.log /home/pi/direwolf.log

echo "[*] Applying DigiPi filesystem overlay"

for d in etc usr var home; do
  if [ -d "$d" ]; then
    echo "  - syncing /$d"
    if [ "$d" = "home" ]; then
      sudo rsync -a \
        --exclude='pi/.config' \
        --exclude='pi/.local' \
        "$d"/ "/$d"/
    else
      sudo rsync -a "$d"/ "/$d"/
    fi
  fi
done

echo "[*] Installing systemd units"
if [ -d systemd/system ]; then
  sudo rsync -a systemd/system/ /etc/systemd/system/
  sudo systemctl daemon-reload
fi

echo "[*] Ensuring localize.env exists"
if [ ! -f "$ENV_FILE" ]; then
  echo "[*] localize.env not found"
  read -rp "Enter your HAM callsign (NEWCALL): " NEWCALL
  echo "NEWCALL=${NEWCALL}" > "$ENV_FILE"
  sudo chown ${DIGIPI_USER}:${DIGIPI_USER} "$ENV_FILE"
  sudo chmod 600 "$ENV_FILE"
else
  echo "[*] localize.env already exists"
fi

PHP_INI=$(php -i 2>/dev/null | awk -F': ' '/^Loaded Configuration File/ {print $2}')
if [ -n "${PHP_INI:-}" ] && [ -f "$PHP_INI" ]; then
  sudo sed -i 's/^short_open_tag\s*=.*/short_open_tag = On/' "$PHP_INI"
  sudo sed -i 's/^display_errors\s*=.*/display_errors = On/' "$PHP_INI"
else
  echo "[!] PHP ini not found; skipping php.ini edits"
fi

sudo rm -f /var/www/html/index.html

echo "[*] Configuring sudoers for web UI controls"
SUDOERS_TMP=$(mktemp)
cat > "$SUDOERS_TMP" <<'EOF'
www-data ALL=(ALL) NOPASSWD: ALL
EOF
if ! sudo cmp -s "$SUDOERS_TMP" /etc/sudoers.d/digipi-www 2>/dev/null; then
  sudo cp "$SUDOERS_TMP" /etc/sudoers.d/digipi-www
  sudo chmod 440 /etc/sudoers.d/digipi-www
  sudo visudo -cf /etc/sudoers.d/digipi-www
fi
rm -f "$SUDOERS_TMP"

echo "[*] Restarting Apache"
sudo systemctl restart apache2 >/dev/null 2>&1 || true

echo "[*] Install complete"
