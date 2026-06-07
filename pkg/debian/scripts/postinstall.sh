#!/usr/bin/env bash

set -Eeuo pipefail

if ! id -u archivebox >/dev/null 2>&1; then
    useradd --system --user-group --shell /bin/bash --home-dir /var/lib/archivebox --create-home archivebox
    echo "[+] Created archivebox system user"
fi

mkdir -p /var/lib/archivebox/.config /var/lib/archivebox/.runtime
chown archivebox:archivebox /var/lib/archivebox
chown -R archivebox:archivebox /var/lib/archivebox/.config /var/lib/archivebox/.runtime
chmod 0755 /var/lib/archivebox
chmod 0700 /var/lib/archivebox/.config /var/lib/archivebox/.runtime

/opt/archivebox/install.sh

if command -v systemctl >/dev/null 2>&1 && [[ -d /run/systemd/system ]]; then
    systemctl daemon-reload

    if systemctl is-enabled archivebox >/dev/null 2>&1; then
        systemctl start archivebox 2>/dev/null || true
        echo "[+] Started archivebox service"
    else
        echo "[i] To start ArchiveBox: sudo systemctl start archivebox"
        echo "[i] To enable on boot:   sudo systemctl enable archivebox"
    fi
fi
