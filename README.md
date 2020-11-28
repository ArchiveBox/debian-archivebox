# debian-archivebox

The official `apt`/`deb` package for [ArchiveBox](https://github.com/ArchiveBox/ArchiveBox), the self-hosted internet archiving solution.

https://launchpad.net/~archivebox/+archive/ubuntu/archivebox/+packages

## Quickstart

**Add the repo to your sources:**
```bash
# on Ubuntu 20.04 and up you can do:
sudo add-apt-repository -u ppa:archivebox/archivebox

# on other systems you should add the repo to your sources manually:
echo "deb http://ppa.launchpad.net/archivebox/archivebox/ubuntu focal main" >> /etc/apt/sources.list
sudo apt update
```

**Install it:**
```bash
sudo apt install archivebox
```

**Try it out:**
```bash
archivebox version

mkdir data && cd data
archivebox init
archivebox add 'https://example.com'
```
---

Tested on Ubuntu 20.04, should work on all Debian/Ubuntu based systems.

---

## Development

The debian package is built using `stdeb`: https://github.com/astraw/stdeb and hosted on Launchpad: https://launchpad.net/~archivebox.

https://launchpad.net/~archivebox/+archive/ubuntu/archivebox/+packages

The config file / package definition is here: [`ArchiveBox/stdeb.cfg`](https://github.com/ArchiveBox/ArchiveBox/blob/master/stdeb.cfg).

To build this package, make sure you are in the ArchiveBox main repo first.

```bash
cd ArchiveBox/
git pull --recurse-submodules

# Build the debian package
./bin/build_deb.sh

# Release the debian package to the LaunchPad PPA
./bin/release.sh
```
