#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

if [[ "$#" -lt 2 ]]; then
    echo "Usage: $0 /path/to/repo /path/to/package.deb [more.deb ...]" >&2
    exit 2
fi

REPO_DIR="$(cd "$1" && pwd)"
shift

SUITE="${APT_SUITE:-dev}"
COMPONENT="${APT_COMPONENT:-main}"
POOL_DIR="$REPO_DIR/pool/main/a/archivebox"
DIST_DIR="$REPO_DIR/dists/$SUITE"

if ! command -v dpkg-scanpackages >/dev/null 2>&1; then
    echo "[X] dpkg-scanpackages is required. Install dpkg-dev." >&2
    exit 1
fi

mkdir -p "$POOL_DIR"
for deb in "$@"; do
    cp "$deb" "$POOL_DIR/"
done

cd "$REPO_DIR"
for arch in amd64 arm64 all; do
    packages_dir="$DIST_DIR/$COMPONENT/binary-$arch"
    mkdir -p "$packages_dir"
    dpkg-scanpackages --multiversion pool /dev/null > "$packages_dir/Packages"
    gzip -9kf "$packages_dir/Packages"
done

release_file="$DIST_DIR/Release"
cat > "$release_file" <<EOF
Origin: ArchiveBox
Label: ArchiveBox
Suite: $SUITE
Codename: $SUITE
Architectures: amd64 arm64 all
Components: $COMPONENT
Description: ArchiveBox third-party Debian packages
Date: $(date -Ru)
EOF

{
    echo "MD5Sum:"
    find "$DIST_DIR/$COMPONENT" -type f | sort | while read -r file; do
        rel="${file#$DIST_DIR/}"
        printf ' %s %16s %s\n' "$(md5sum "$file" | awk '{print $1}')" "$(wc -c < "$file")" "$rel"
    done
    echo "SHA256:"
    find "$DIST_DIR/$COMPONENT" -type f | sort | while read -r file; do
        rel="${file#$DIST_DIR/}"
        printf ' %s %16s %s\n' "$(sha256sum "$file" | awk '{print $1}')" "$(wc -c < "$file")" "$rel"
    done
} >> "$release_file"

echo "[√] Updated apt repo at $REPO_DIR ($SUITE/$COMPONENT)"
