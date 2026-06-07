#!/usr/bin/env bash

set -Eeuo pipefail

if command -v systemctl >/dev/null 2>&1 && [[ -d /run/systemd/system ]]; then
    systemctl stop archivebox 2>/dev/null || true
fi

if [[ "${1:-}" == "remove" || "${1:-}" == "purge" ]]; then
    if command -v systemctl >/dev/null 2>&1 && [[ -d /run/systemd/system ]]; then
        systemctl disable archivebox 2>/dev/null || true
    fi

    echo "[+] Removing ArchiveBox runtime from /opt/archivebox..."
    rm -rf /opt/archivebox/venv /opt/archivebox/uv /opt/archivebox/cache

    echo "[i] ArchiveBox data in /var/lib/archivebox has not been removed."
    echo "    Remove it manually if you no longer need it:"
    echo "      sudo rm -rf /var/lib/archivebox"
    echo "      sudo userdel archivebox"
fi
