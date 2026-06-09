# ArchiveBox Debian Package

This repo builds the `archivebox` `.deb` package used by `apt` install on Ubuntu/Debian-based systems.

The package is just a thin apt wrapper around the normal Python install flow, it's not a "proper debian package" because it depends on postinstall scripts to setup python, uv, and archivebox.

1. `apt` installs `/usr/bin/archivebox`, `/opt/archivebox/install.sh`, a systemd
   unit, and a small package metadata file.
2. `postinstall` reuses a suitable host `uv` when one is already installed, or
   installs `uv` into `/opt/archivebox/uv` as a fallback.
3. `uv` resolves Python 3.13 from the host or its normal managed-Python
   location for the `archivebox` system user.
4. `uv pip install` installs ArchiveBox into `/opt/archivebox/venv`.
5. Runtime extractor/plugin dependencies remain managed by `archivebox install`, and only your selected plugin dependencies are lazy-installed on first use.

## Install

```bash
echo 'deb [trusted=yes] https://archivebox.github.io/debian-archivebox dev main' | sudo tee /etc/apt/sources.list.d/archivebox.list
sudo apt update
sudo apt install archivebox
```

Then initialize an archive:

```bash
mkdir -p ~/archivebox/data && cd ~/archivebox/data
archivebox init           # initialize a new collection in the current dir
archivebox version        # see version of all detected installed dependencies
archivebox install        # use sudo to get apt dependencies auto-installed too
archivebox add 'https://example.com'
```

The package creates the `archivebox` system user and the state/config/runtime
directories needed for systemd usage. Regular users can keep archives anywhere
they own; usually only `archivebox install` is needed to get all plugin dependencies, 
but if you are missing some runtime apt dependencies, then you can run `sudo archivebox install` 
to get them (don't worry, it wont leave the collection owned by root).

<br/>

---
---

<br/>

## Building the `.deb` From Source

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

Before publishing, CI verifies the built package on an Ubuntu GitHub Actions
runner by installing the `.deb` with `apt`, running the installed
`/usr/bin/archivebox` as both root and a normal passwordless-sudo user, running
full `archivebox install` flows for both, archiving a local fixture page as the
normal user, and asserting that `index.sqlite3` plus real files under `archive/`
are written to disk.
