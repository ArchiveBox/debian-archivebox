# ArchiveBox Debian Package

This repo builds the third-party `archivebox` `.deb` package.

The package intentionally does not translate ArchiveBox Python/plugin
dependencies into Debian package dependencies. It is a thin apt wrapper around
the normal Python install flow:

1. `apt` installs `/usr/bin/archivebox`, `/opt/archivebox/install.sh`, a systemd
   unit, and a small package metadata file.
2. `postinstall` reuses a suitable host `uv` when one is already installed, or
   installs `uv` into `/opt/archivebox/uv` as a fallback.
3. `uv` installs CPython 3.13 into `/opt/archivebox/python`.
4. `uv pip install` installs ArchiveBox into `/opt/archivebox/venv`.
5. Runtime extractor/plugin dependencies remain managed by `archivebox install`.

## Install

```bash
echo 'deb [trusted=yes] https://archivebox.github.io/debian-archivebox dev main' | sudo tee /etc/apt/sources.list.d/archivebox.list
sudo apt update
sudo apt install archivebox
```

Then initialize an archive:

```bash
mkdir -p ~/archivebox/data
cd ~/archivebox/data
archivebox init --install
```

The unsigned apt repo is the minimally viable install path. If signing is added
later, users can switch from `[trusted=yes]` to a normal `signed-by=` keyring.

## Build Locally

```bash
go install github.com/goreleaser/nfpm/v2/cmd/nfpm@latest
./bin/build_deb.sh
sudo apt install ./dist/archivebox_*.deb
```

By default, `bin/build_deb.sh` packages the latest `ArchiveBox/ArchiveBox:dev`
commit and stores that exact source archive URL in `/opt/archivebox/package.env`.
Override the source when needed:

```bash
ARCHIVEBOX_REF=v0.9.34 ./bin/build_deb.sh
ARCHIVEBOX_PIP_SPEC='archivebox==0.9.34' DEB_VERSION='0.9.34' ./bin/build_deb.sh
```

## Automation

`.github/workflows/build.yml` rebuilds from `ArchiveBox:dev` by:

- `workflow_dispatch` for manual rebuilds
- `repository_dispatch` with type `archivebox-dev-updated`
- a scheduled poll every 30 minutes

The workflow publishes:

- a prerelease named `dev-<upstream-sha>`
- the updated apt repository on `gh-pages`

A push webhook or upstream workflow can trigger an immediate rebuild with:

```bash
gh api repos/ArchiveBox/debian-archivebox/dispatches \
  -f event_type=archivebox-dev-updated \
  -F client_payload[ref]=dev
```
