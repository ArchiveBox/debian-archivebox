#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

grep -Fq "if: github.ref == 'refs/heads/main' && !contains(inputs.archivebox_version, 'rc')" \
    "$REPO_DIR/.github/workflows/build.yml"

build_deb() {
    local version="$1"
    local package_dir="$WORK_DIR/package-$version"
    local deb_path="$WORK_DIR/archivebox_${version}_all.deb"

    mkdir -p "$package_dir/DEBIAN"
    cat > "$package_dir/DEBIAN/control" <<EOF
Package: archivebox
Version: $version
Architecture: all
Maintainer: ArchiveBox <support@archivebox.io>
Description: ArchiveBox repository regression fixture
EOF
    dpkg-deb --build "$package_dir" "$deb_path" >/dev/null
    printf '%s\n' "$deb_path"
}

APT_REPO="$WORK_DIR/apt-repo"
mkdir -p "$APT_REPO"

OLD_DEB="$(build_deb '0.9.35rc175~dev1785342002')"
NEW_DEB="$(build_deb '0.9.35~rc190')"

"$REPO_DIR/bin/update_apt_repo.sh" "$APT_REPO" "$OLD_DEB"
"$REPO_DIR/bin/update_apt_repo.sh" "$APT_REPO" "$NEW_DEB"

PACKAGES="$APT_REPO/dists/dev/main/binary-all/Packages"
test "$(find "$APT_REPO/pool/main/a/archivebox" -maxdepth 1 -type f -name 'archivebox_*.deb' | wc -l)" -eq 2
grep -Fx 'Version: 0.9.35~rc190' "$PACKAGES"
if grep -Fq 'Version: 0.9.35rc175~dev1785342002' "$PACKAGES"; then
    echo '[X] Obsolete ArchiveBox package remained in the apt index.' >&2
    exit 1
fi

echo '[√] Apt repository indexes the latest package and preserves previous files.'
