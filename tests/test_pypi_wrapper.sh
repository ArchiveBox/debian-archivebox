#!/usr/bin/env bash

set -Eeuo pipefail

if [[ "$#" -ne 2 ]]; then
    echo "Usage: $0 /path/to/package.deb ARCHIVEBOX_VERSION" >&2
    exit 2
fi

DEB_FILE="$1"
EXPECTED_VERSION="$2"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT

ar p "$DEB_FILE" data.tar.xz | tar -xOJf - ./opt/archivebox/package.env > "$TEST_DIR/package.env"

# shellcheck disable=SC1091
source "$TEST_DIR/package.env"

test "$ARCHIVEBOX_VERSION" = "$EXPECTED_VERSION"
test -n "$ARCHIVEBOX_WHEEL_URL"
test -n "$ARCHIVEBOX_WHEEL_SHA256"
test "${#ARCHIVEBOX_WHEEL_SHA256}" -eq 64

case "$ARCHIVEBOX_WHEEL_URL" in
    https://files.pythonhosted.org/packages/*/archivebox-"$EXPECTED_VERSION"-*.whl) ;;
    *)
        echo "[X] Unexpected ArchiveBox wheel URL: $ARCHIVEBOX_WHEEL_URL" >&2
        exit 1
        ;;
esac

curl -fsSL "$ARCHIVEBOX_WHEEL_URL" -o "$TEST_DIR/archivebox.whl"
if command -v sha256sum >/dev/null 2>&1; then
    ACTUAL_SHA256="$(sha256sum "$TEST_DIR/archivebox.whl" | awk '{print $1}')"
else
    ACTUAL_SHA256="$(shasum -a 256 "$TEST_DIR/archivebox.whl" | awk '{print $1}')"
fi
test "$ACTUAL_SHA256" = "$ARCHIVEBOX_WHEEL_SHA256"

echo "[√] Debian wrapper points to archivebox==$EXPECTED_VERSION on PyPI."
