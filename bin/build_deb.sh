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

if ! command -v nfpm >/dev/null 2>&1; then
    echo "[X] nfpm is required to build the .deb package." >&2
    echo "    Install it with: go install github.com/goreleaser/nfpm/v2/cmd/nfpm@latest" >&2
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
} > "$PACKAGE_ENV"

cat > "$DIST_DIR/build.env" <<EOF
ARCHIVEBOX_VERSION=$ARCHIVEBOX_VERSION
ARCHIVEBOX_DEB_VERSION=$DEB_VERSION
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
echo "    archivebox==$ARCHIVEBOX_VERSION"
