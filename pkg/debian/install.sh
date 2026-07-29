#!/usr/bin/env bash

set -Eeuo pipefail

ARCHIVEBOX_HOME="${ARCHIVEBOX_HOME:-/opt/archivebox}"
ARCHIVEBOX_VENV="${ARCHIVEBOX_VENV:-$ARCHIVEBOX_HOME/venv}"
ARCHIVEBOX_UV_BIN_DIR="${ARCHIVEBOX_UV_BIN_DIR:-$ARCHIVEBOX_HOME/uv/bin}"
ARCHIVEBOX_UV="${ARCHIVEBOX_UV:-$ARCHIVEBOX_UV_BIN_DIR/uv}"
ARCHIVEBOX_PACKAGE_ENV="${ARCHIVEBOX_PACKAGE_ENV:-$ARCHIVEBOX_HOME/package.env}"
ARCHIVEBOX_USER="${ARCHIVEBOX_USER:-archivebox}"
ARCHIVEBOX_STATE_DIR="${ARCHIVEBOX_STATE_DIR:-/var/lib/archivebox}"

export UV_CACHE_DIR="${UV_CACHE_DIR:-$ARCHIVEBOX_HOME/cache/uv}"
export UV_LINK_MODE="${UV_LINK_MODE:-copy}"
export UV_NO_CONFIG=1

if [[ -f "$ARCHIVEBOX_PACKAGE_ENV" ]]; then
    # shellcheck disable=SC1090
    source "$ARCHIVEBOX_PACKAGE_ENV"
fi

: "${ARCHIVEBOX_VERSION:?missing ARCHIVEBOX_VERSION in $ARCHIVEBOX_PACKAGE_ENV}"
ARCHIVEBOX_PIP_SPEC="archivebox==$ARCHIVEBOX_VERSION"

mkdir -p "$ARCHIVEBOX_HOME" "$ARCHIVEBOX_UV_BIN_DIR" "$UV_CACHE_DIR" "$ARCHIVEBOX_VENV"

if [[ "${EUID:-$(id -u)}" == "0" ]]; then
    if ! id -u "$ARCHIVEBOX_USER" >/dev/null 2>&1; then
        echo "[X] The $ARCHIVEBOX_USER system user must exist before installing ArchiveBox." >&2
        exit 1
    fi

    ARCHIVEBOX_USER_HOME="$(getent passwd "$ARCHIVEBOX_USER" | cut -d: -f6)"
    if [[ -z "$ARCHIVEBOX_USER_HOME" ]]; then
        echo "[X] The $ARCHIVEBOX_USER system user has no home directory." >&2
        exit 1
    fi

    mkdir -p "$ARCHIVEBOX_USER_HOME/.local" "$ARCHIVEBOX_USER_HOME/.cache" "$ARCHIVEBOX_USER_HOME/.config"
    chown -R "$ARCHIVEBOX_USER:$ARCHIVEBOX_USER" \
        "$ARCHIVEBOX_UV_BIN_DIR" \
        "$ARCHIVEBOX_VENV" \
        "$UV_CACHE_DIR" \
        "$ARCHIVEBOX_USER_HOME/.local" \
        "$ARCHIVEBOX_USER_HOME/.cache" \
        "$ARCHIVEBOX_USER_HOME/.config"

    runuser -u "$ARCHIVEBOX_USER" -- env \
        HOME="$ARCHIVEBOX_USER_HOME" \
        USER="$ARCHIVEBOX_USER" \
        LOGNAME="$ARCHIVEBOX_USER" \
        PATH="$ARCHIVEBOX_UV_BIN_DIR:$PATH" \
        XDG_CONFIG_HOME="$ARCHIVEBOX_USER_HOME/.config" \
        XDG_CACHE_HOME="$ARCHIVEBOX_USER_HOME/.cache" \
        ARCHIVEBOX_HOME="$ARCHIVEBOX_HOME" \
        ARCHIVEBOX_UV_BIN_DIR="$ARCHIVEBOX_UV_BIN_DIR" \
        ARCHIVEBOX_UV="$ARCHIVEBOX_UV" \
        ARCHIVEBOX_VENV="$ARCHIVEBOX_VENV" \
        ARCHIVEBOX_PACKAGE_ENV="$ARCHIVEBOX_PACKAGE_ENV" \
        ARCHIVEBOX_VERSION="$ARCHIVEBOX_VERSION" \
        ARCHIVEBOX_USER="$ARCHIVEBOX_USER" \
        ARCHIVEBOX_STATE_DIR="$ARCHIVEBOX_STATE_DIR" \
        UV_CACHE_DIR="$UV_CACHE_DIR" \
        UV_LINK_MODE="$UV_LINK_MODE" \
        UV_NO_CONFIG="$UV_NO_CONFIG" \
        "$0"

    chmod 0755 "$ARCHIVEBOX_USER_HOME" "$ARCHIVEBOX_USER_HOME/.local" "$ARCHIVEBOX_USER_HOME/.local/share" "$ARCHIVEBOX_USER_HOME/.local/share/uv" 2>/dev/null || true
    chmod -R a+rX "$ARCHIVEBOX_USER_HOME/.local/share/uv/python" "$ARCHIVEBOX_VENV" 2>/dev/null || true
    echo "[√] ArchiveBox installed."
    echo "    Run: archivebox version"
    exit 0
fi

if ! command -v curl >/dev/null 2>&1; then
    echo "[X] curl is required to install uv." >&2
    exit 1
fi

echo "[+] Installing/updating uv in $ARCHIVEBOX_UV_BIN_DIR..."
curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="$ARCHIVEBOX_UV_BIN_DIR" sh

if [[ ! -x "$ARCHIVEBOX_UV" ]]; then
    echo "[X] uv setup completed, but $ARCHIVEBOX_UV does not exist." >&2
    exit 1
fi

if [[ -x "$ARCHIVEBOX_VENV/bin/python" ]]; then
    if ! "$ARCHIVEBOX_VENV/bin/python" - <<'PY'
import sys
raise SystemExit(0 if sys.version_info[:2] >= (3, 13) else 1)
PY
    then
        echo "[i] Existing virtualenv is older than Python 3.13; recreating it."
        rm -rf "$ARCHIVEBOX_VENV"
    fi
fi

echo "[+] Creating ArchiveBox virtualenv in $ARCHIVEBOX_VENV..."
"$ARCHIVEBOX_UV" venv "$ARCHIVEBOX_VENV" --python 3.13 --seed --allow-existing

echo "[+] Installing ArchiveBox with uv pip:"
echo "    $ARCHIVEBOX_PIP_SPEC"
"$ARCHIVEBOX_UV" pip install \
    --python "$ARCHIVEBOX_VENV/bin/python" \
    --upgrade \
    --compile-bytecode \
    "$ARCHIVEBOX_PIP_SPEC"

echo "[√] ArchiveBox installed."
echo "    Run: archivebox version"
