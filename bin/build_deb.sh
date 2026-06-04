#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR"

ARCHIVEBOX_REPO_URL="${ARCHIVEBOX_REPO_URL:-https://github.com/ArchiveBox/ArchiveBox.git}"
ARCHIVEBOX_REF="${ARCHIVEBOX_REF:-dev}"
BUILD_DIR="${BUILD_DIR:-$REPO_DIR/build}"
DIST_DIR="${DIST_DIR:-$REPO_DIR/dist}"
UPSTREAM_DIR="$BUILD_DIR/archivebox-upstream"

if ! command -v git >/dev/null 2>&1; then
    echo "[X] git is required to resolve ArchiveBox:${ARCHIVEBOX_REF}" >&2
    exit 1
fi

if ! command -v nfpm >/dev/null 2>&1; then
    echo "[X] nfpm is required to build the .deb package." >&2
    echo "    Install it with: go install github.com/goreleaser/nfpm/v2/cmd/nfpm@latest" >&2
    exit 1
fi

rm -rf "$UPSTREAM_DIR"
mkdir -p "$BUILD_DIR" "$DIST_DIR"

echo "[+] Fetching ArchiveBox ${ARCHIVEBOX_REPO_URL}#${ARCHIVEBOX_REF}..."
if ! git clone --depth 1 --branch "$ARCHIVEBOX_REF" "$ARCHIVEBOX_REPO_URL" "$UPSTREAM_DIR" >/dev/null 2>&1; then
    git init -q "$UPSTREAM_DIR"
    git -C "$UPSTREAM_DIR" remote add origin "$ARCHIVEBOX_REPO_URL"
    git -C "$UPSTREAM_DIR" fetch --depth 1 origin "$ARCHIVEBOX_REF"
    git -C "$UPSTREAM_DIR" checkout -q FETCH_HEAD
fi

ARCHIVEBOX_UPSTREAM_SHA="$(git -C "$UPSTREAM_DIR" rev-parse HEAD)"
ARCHIVEBOX_UPSTREAM_SHORT_SHA="${ARCHIVEBOX_UPSTREAM_SHA:0:12}"
ARCHIVEBOX_COMMIT_TS="$(git -C "$UPSTREAM_DIR" show -s --format=%ct HEAD)"
ARCHIVEBOX_VERSION="$(
    python3 - "$UPSTREAM_DIR/pyproject.toml" <<'PY'
from pathlib import Path
import re
import sys

text = Path(sys.argv[1]).read_text()
match = re.search(r'^version = "([^"]+)"$', text, re.MULTILINE)
if not match:
    raise SystemExit("failed to find ArchiveBox version in pyproject.toml")
print(match.group(1))
PY
)"

ARCHIVEBOX_PIP_SPEC="${ARCHIVEBOX_PIP_SPEC:-archivebox @ https://github.com/ArchiveBox/ArchiveBox/archive/${ARCHIVEBOX_UPSTREAM_SHA}.tar.gz}"
DEB_VERSION="${DEB_VERSION:-${ARCHIVEBOX_VERSION}~dev${ARCHIVEBOX_COMMIT_TS}+${ARCHIVEBOX_UPSTREAM_SHORT_SHA}}"
DEB_ARCH="${DEB_ARCH:-all}"

PACKAGE_ENV="$BUILD_DIR/package.env"
{
    printf 'ARCHIVEBOX_VERSION=%q\n' "$ARCHIVEBOX_VERSION"
    printf 'ARCHIVEBOX_DEB_VERSION=%q\n' "$DEB_VERSION"
    printf 'ARCHIVEBOX_REF=%q\n' "$ARCHIVEBOX_REF"
    printf 'ARCHIVEBOX_REPO_URL=%q\n' "$ARCHIVEBOX_REPO_URL"
    printf 'ARCHIVEBOX_UPSTREAM_SHA=%q\n' "$ARCHIVEBOX_UPSTREAM_SHA"
    printf 'ARCHIVEBOX_PIP_SPEC=%q\n' "$ARCHIVEBOX_PIP_SPEC"
} > "$PACKAGE_ENV"

cat > "$DIST_DIR/build.env" <<EOF
ARCHIVEBOX_VERSION=$ARCHIVEBOX_VERSION
ARCHIVEBOX_DEB_VERSION=$DEB_VERSION
ARCHIVEBOX_REF=$ARCHIVEBOX_REF
ARCHIVEBOX_UPSTREAM_SHA=$ARCHIVEBOX_UPSTREAM_SHA
ARCHIVEBOX_UPSTREAM_SHORT_SHA=$ARCHIVEBOX_UPSTREAM_SHORT_SHA
ARCHIVEBOX_PIP_SPEC=$ARCHIVEBOX_PIP_SPEC
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
echo "    $ARCHIVEBOX_PIP_SPEC"
