# ArchiveBox Debian Package

This repo builds the `archivebox` `.deb` package used by `apt` install on Ubuntu/Debian-based systems.

The package is just a thin apt wrapper around the normal Python install flow, it's not a "proper debian package" because it depends on postinstall scripts to setup python, uv, and archivebox.

1. `apt` installs `/usr/bin/archivebox`, `/opt/archivebox/install.sh`, a systemd
   unit, and a small package metadata file.
2. `postinstall` installs the official prebuilt `uv` into `/opt/archivebox/uv`.
3. `uv` resolves Python 3.13 from the host or its normal managed-Python
   location for the `archivebox` system user.
4. `uv pip install` installs ArchiveBox into `/opt/archivebox/venv`.
5. `archivebox install` installs the runtime dependencies for all enabled extractor plugins.

## Install

```bash
echo 'deb [trusted=yes] https://archivebox.github.io/debian-archivebox dev main' | sudo tee /etc/apt/sources.list.d/archivebox.list
sudo apt update
sudo apt install archivebox
```

The systemd service uses `/var/lib/archivebox/data` as its collection. Install the
extractor dependencies before starting it, then create its admin user:

```bash
cd /var/lib/archivebox/data
sudo archivebox install
sudo systemctl enable --now archivebox
sudo -u archivebox -H bash -lc 'cd /var/lib/archivebox/data && archivebox manage createsuperuser'
```

The package creates the `archivebox` system user and the state/config/runtime
directories needed for systemd usage. To use a separate personal collection
instead, run the normal commands in a directory you own:

```bash
mkdir -p ~/archivebox/data && cd ~/archivebox/data
archivebox init
archivebox install
archivebox add 'https://example.com'
```

If managed plugin installation needs system packages, run `sudo archivebox
install` from the collection directory. The wrapper drops privileges to the
collection owner and does not recursively change collection ownership.

<br/>

---
---

<br/>

## Building the `.deb` Wrapper

```bash
go install github.com/goreleaser/nfpm/v2/cmd/nfpm@latest
ARCHIVEBOX_VERSION=0.9.35rc175 ./bin/build_deb.sh
sudo apt install ./dist/archivebox_*.deb
```

`ARCHIVEBOX_VERSION` is the only ArchiveBox release input. The package stores
that version in `/opt/archivebox/package.env` and installs
`archivebox==VERSION` from PyPI; it never clones or embeds the ArchiveBox source
tree.

Before publishing, CI verifies the built package on an Ubuntu GitHub Actions
runner by installing the `.deb` with `apt`, running the installed
`/usr/bin/archivebox` as both root and a normal passwordless-sudo user, running
full `archivebox install` flows for both, archiving a local fixture page as the
normal user, and asserting that `index.sqlite3` plus real files under `archive/`
are written to disk.
