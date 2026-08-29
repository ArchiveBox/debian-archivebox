#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR"

ARCHIVEBOX_VERSION="${ARCHIVEBOX_VERSION:-}"
BUILD_DIR="${BUILD_DIR:-$REPO_DIR/build}"
DIST_DIR="${DIST_DIR:-$REPO_DIR/dist}"

if [[ -z "$ARCHIVEBOX_VERSION" ]]; then
    echo "[X] ARCHIVEBOX_VERSION is required." >&2
    exit 1
fi

for binary in curl jq; do
    if ! command -v "$binary" >/dev/null 2>&1; then
        echo "[X] $binary is required to resolve the published ArchiveBox wheel." >&2
        exit 1
    fi
done

if ! command -v nfpm >/dev/null 2>&1; then
    echo "[X] nfpm is required to build the .deb package." >&2
    echo "    Install it with: go install github.com/goreleaser/nfpm/v2/cmd/nfpm@latest" >&2
    exit 1
fi

echo "[+] Resolving archivebox==$ARCHIVEBOX_VERSION from PyPI..."
PYPI_RELEASE="$(curl -fsSL "https://pypi.org/pypi/archivebox/$ARCHIVEBOX_VERSION/json")"
if [[ "$(jq -r '.info.version' <<< "$PYPI_RELEASE")" != "$ARCHIVEBOX_VERSION" ]]; then
    echo "[X] PyPI returned the wrong ArchiveBox version." >&2
    exit 1
fi
WHEEL_COUNT="$(jq '[.urls[] | select(.packagetype == "bdist_wheel")] | length' <<< "$PYPI_RELEASE")"
if [[ "$WHEEL_COUNT" -ne 1 ]]; then
    echo "[X] Expected one PyPI wheel for archivebox==$ARCHIVEBOX_VERSION, found $WHEEL_COUNT." >&2
    exit 1
fi
ARCHIVEBOX_WHEEL_URL="$(jq -r '.urls[] | select(.packagetype == "bdist_wheel") | .url' <<< "$PYPI_RELEASE")"
ARCHIVEBOX_WHEEL_SHA256="$(jq -r '.urls[] | select(.packagetype == "bdist_wheel") | .digests.sha256' <<< "$PYPI_RELEASE")"
if [[ ! "$ARCHIVEBOX_WHEEL_URL" =~ ^https://files\.pythonhosted\.org/packages/.+\.whl$ ]] || [[ ! "$ARCHIVEBOX_WHEEL_SHA256" =~ ^[0-9a-f]{64}$ ]]; then
    echo "[X] PyPI returned invalid ArchiveBox wheel metadata." >&2
    exit 1
fi

mkdir -p "$BUILD_DIR" "$DIST_DIR"
rm -f "$DIST_DIR"/archivebox_*.deb "$DIST_DIR/build.env"

DEB_VERSION="${ARCHIVEBOX_VERSION/rc/~rc}"
DEB_ARCH="all"

PACKAGE_ENV="$BUILD_DIR/package.env"
{
    printf 'ARCHIVEBOX_VERSION=%q\n' "$ARCHIVEBOX_VERSION"
    printf 'ARCHIVEBOX_DEB_VERSION=%q\n' "$DEB_VERSION"
    printf 'ARCHIVEBOX_WHEEL_URL=%q\n' "$ARCHIVEBOX_WHEEL_URL"
    printf 'ARCHIVEBOX_WHEEL_SHA256=%q\n' "$ARCHIVEBOX_WHEEL_SHA256"
} > "$PACKAGE_ENV"

cat > "$DIST_DIR/build.env" <<EOF
ARCHIVEBOX_VERSION=$ARCHIVEBOX_VERSION
ARCHIVEBOX_DEB_VERSION=$DEB_VERSION
ARCHIVEBOX_WHEEL_URL=$ARCHIVEBOX_WHEEL_URL
ARCHIVEBOX_WHEEL_SHA256=$ARCHIVEBOX_WHEEL_SHA256
EOF

export DEB_VERSION
export DEB_ARCH

echo "[+] Building archivebox_${DEB_VERSION}_${DEB_ARCH}.deb..."
nfpm package \
    --config "$REPO_DIR/pkg/debian/nfpm.yaml" \
    --packager deb \
    --target "$DIST_DIR/"

echo
echo "[√] Built:"
ls -lh "$DIST_DIR"/*.deb
echo
echo "[i] Package installs:"
echo "    archivebox==$ARCHIVEBOX_VERSION from $ARCHIVEBOX_WHEEL_URL"
