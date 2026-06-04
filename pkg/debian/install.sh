#!/usr/bin/env bash

set -Eeuo pipefail

ARCHIVEBOX_HOME="${ARCHIVEBOX_HOME:-/opt/archivebox}"
ARCHIVEBOX_VENV="${ARCHIVEBOX_VENV:-$ARCHIVEBOX_HOME/venv}"
ARCHIVEBOX_UV_BIN_DIR="${ARCHIVEBOX_UV_BIN_DIR:-$ARCHIVEBOX_HOME/uv/bin}"
ARCHIVEBOX_UV="${ARCHIVEBOX_UV:-$ARCHIVEBOX_UV_BIN_DIR/uv}"
ARCHIVEBOX_PACKAGE_ENV="${ARCHIVEBOX_PACKAGE_ENV:-$ARCHIVEBOX_HOME/package.env}"
ARCHIVEBOX_UV_INSTALLER_URL="${ARCHIVEBOX_UV_INSTALLER_URL:-https://astral.sh/uv/install.sh}"
ARCHIVEBOX_USE_SYSTEM_UV="${ARCHIVEBOX_USE_SYSTEM_UV:-1}"

export UV_CACHE_DIR="${UV_CACHE_DIR:-$ARCHIVEBOX_HOME/cache/uv}"
export UV_PYTHON_INSTALL_DIR="${UV_PYTHON_INSTALL_DIR:-$ARCHIVEBOX_HOME/python}"
export UV_LINK_MODE="${UV_LINK_MODE:-copy}"
export UV_NO_CONFIG=1

if [[ -f "$ARCHIVEBOX_PACKAGE_ENV" ]]; then
    # shellcheck disable=SC1090
    source "$ARCHIVEBOX_PACKAGE_ENV"
fi

ARCHIVEBOX_PIP_SPEC="${ARCHIVEBOX_PIP_SPEC:-archivebox}"

mkdir -p "$ARCHIVEBOX_HOME" "$ARCHIVEBOX_UV_BIN_DIR" "$UV_CACHE_DIR" "$UV_PYTHON_INSTALL_DIR"

uv_is_suitable() {
    local uv_bin="$1"

    [[ -x "$uv_bin" ]] || return 1
    "$uv_bin" python install --help >/dev/null 2>&1 || return 1
    "$uv_bin" venv --help 2>/dev/null | grep -q -- "--managed-python" || return 1
    "$uv_bin" pip install --help 2>/dev/null | grep -q -- "--compile-bytecode" || return 1
}

HOST_UV=""
if [[ "$ARCHIVEBOX_USE_SYSTEM_UV" == "1" ]]; then
    HOST_UV="$(command -v uv 2>/dev/null || true)"
fi

if [[ -n "$HOST_UV" ]] && uv_is_suitable "$HOST_UV"; then
    echo "[+] Using existing host uv: $HOST_UV"
    ln -sfn "$HOST_UV" "$ARCHIVEBOX_UV"
else
    if ! command -v curl >/dev/null 2>&1; then
        echo "[X] curl is required to install uv." >&2
        exit 1
    fi

    echo "[+] Installing/updating uv in $ARCHIVEBOX_UV_BIN_DIR..."
    curl -LsSf "$ARCHIVEBOX_UV_INSTALLER_URL" | env UV_INSTALL_DIR="$ARCHIVEBOX_UV_BIN_DIR" sh
fi

if [[ ! -x "$ARCHIVEBOX_UV" ]]; then
    echo "[X] uv setup completed, but $ARCHIVEBOX_UV does not exist." >&2
    exit 1
fi

echo "[+] Installing uv-managed Python 3.13..."
"$ARCHIVEBOX_UV" python install 3.13 --install-dir "$UV_PYTHON_INSTALL_DIR"

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
"$ARCHIVEBOX_UV" venv "$ARCHIVEBOX_VENV" --managed-python --python 3.13 --seed --allow-existing

echo "[+] Installing ArchiveBox with uv pip:"
echo "    $ARCHIVEBOX_PIP_SPEC"
"$ARCHIVEBOX_UV" pip install \
    --python "$ARCHIVEBOX_VENV/bin/python" \
    --upgrade \
    --compile-bytecode \
    "$ARCHIVEBOX_PIP_SPEC"

echo "[√] ArchiveBox installed."
echo "    Run: archivebox version"
