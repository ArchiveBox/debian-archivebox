# debian-archivebox

The official `apt`/`deb` package for [ArchiveBox](https://github.com/ArchiveBox/ArchiveBox), the self-hosted internet archiving solution.

https://launchpad.net/~archivebox/+archive/ubuntu/archivebox/+packages

## Quickstart

**Add the repo to your sources:**
```bash
# on Ubuntu 20.04 and up you can do:
sudo add-apt-repository -u ppa:archivebox/archivebox

# on other systems you should add the repo to your sources manually:
echo "deb http://ppa.launchpad.net/archivebox/archivebox/ubuntu focal main" > /etc/apt/sources.list.d/archivebox.list
echo "deb-src http://ppa.launchpad.net/archivebox/archivebox/ubuntu focal main" >> /etc/apt/sources.list.d/archivebox.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C258F79DCC02E369
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
apt upgrade -qq
apt install -y python3 python3-dev python3-pip python3-venv python3-all python-all \
            dh-python debhelper devscripts dput software-properties-common \
            python3-distutils python3-setuptools python3-wheel python3-stdeb jq fakeroot
python3 -m pip install setuptools stdeb wheel

cd ArchiveBox/
git pull --recurse-submodules

# Build the debian package
./bin/build_deb.sh

# Install the built package locally during testing
apt install ./deb_dist/archivebox_0.4.24-1_all.deb
# or:
dpkg -i ./deb_dist/archivebox_0.4.24-1_all.deb

# Push the Apt/Debian package to the LaunchPad PPA
./bin/release.sh
```


To setup your GPG keys for signing the debian package these commands may be helpful:
```bash
gpg --refresh-keys
gpg --list-keys
gpg --export ${ID} > public.key
gpg --export-secret-key ${ID} > private.key

gpg --import public.key
gpg --import --allow-secret-key-import private.key

# test that it works
debsign -k YOURGPGKEYID deb_dist/archivebox_*_source.changes
gpg --verify YOURGPGKEYID deb_dist/archivebox_*_source.changes
```

A full guide for doing Python packaging on Debian with `stdeb` is available here: https://docs.monadical.com/s/BkF2EoKqw


TODO: switch to FPM? https://fpm.readthedocs.io/en/latest/intro.html
