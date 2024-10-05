> [!IMPORTANT]
> ## ✨ ArchiveBox no longer needs to be `apt`-installed
>
> ✅ ArchiveBox still fully supports Ubuntu / Debian, don't worry!  
> 📦 Just install it using `pip` (or `pipx`) instead now:
> ```bash
> mkdir -p ~/archivebox/data
> cd ~/archivebox/data     # (for example, can be anywhere)
>
> pip install archivebox   # just use pip to get archivebox
> archivebox install       # then finish installing dependencies
> ```
> If you see `permission denied`, some dependencies need sudo to install.  
> Run `sudo archivebox install`, or install the indicated packages manually.


---

## Historical Context

We moved away from `apt` because ArchiveBox needs to be able to update its dependencies more frequently than the Debian packaging ecosystem allows, and providing workarounds and support for broken debian installs using pinned older versions was taking up too much of our time.  

Now we do something similar to [`playwright`](https://playwright.dev/python/docs/browsers#install-browsers) where the base package is provided via `pip`,
and then you call `archivebox install` to finish installing any system dependencies that are still needed. ArchiveBox uses our own new [`pydantic-pkgr`](https://github.com/ArchiveBox/pydantic-pkgr) library (*check it out!*) to manage
it's runtime dependencies, which in turn relies on the excellent [`pyinfra`](https://pyinfra.com/) library (and/or [`ansible`](https://ansible.readthedocs.io/)) to do the actual installing.

### Prefer doing it the old way?

**See here for manual install instructions for all of ArchiveBox's dependencies on Ubuntu/Debian:**  
https://github.com/ArchiveBox/ArchiveBox/wiki/Install#option-c-bare-metal-setup

<details><summary>Or expand to see old README for this repo (only useful for historical context)</summary>

## ~~Quickstart~~

~~**Add the repo to your sources:**~~
```bash
# on Ubuntu 20.04 and up you can do:
sudo add-apt-repository -u ppa:archivebox/archivebox

# on other systems you should add the repo to your sources manually:
echo "deb http://ppa.launchpad.net/archivebox/archivebox/ubuntu focal main" > /etc/apt/sources.list.d/archivebox.list
echo "deb-src http://ppa.launchpad.net/archivebox/archivebox/ubuntu focal main" >> /etc/apt/sources.list.d/archivebox.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C258F79DCC02E369
sudo apt update
```

~~**Install it:**~~
```bash
sudo apt install archivebox

# get the latest version of archivebox its pip depenencies from PyPI
pip install --upgrade --ignore-installed archivebox yt-dlp playwright
playwright install --with-deps chromium
```

~~**Try it out:**~~
```bash
archivebox version

mkdir -p ~/archivebox/data && cd ~/archivebox/data
archivebox init --setup
archivebox add 'https://example.com'
archivebox help
```
---

~~Tested on Ubuntu 22.04, should work on all Debian/Ubuntu based systems.~~

---

## ~~Development~~

~~The debian package is built using `stdeb`: https://github.com/astraw/stdeb and hosted on Launchpad: https://launchpad.net/~archivebox.~~

~~https://launchpad.net/~archivebox/+archive/ubuntu/archivebox/+packages~~

~~The config file / package definition is here: [`ArchiveBox/stdeb.cfg`](https://github.com/ArchiveBox/ArchiveBox/blob/master/stdeb.cfg).~~

~~To build this package, make sure you are in the ArchiveBox main repo first.~~

```bash
apt upgrade -qq
apt install -y python3 python3-dev python3-pip python3-venv python3-all python-all \
            dh-python debhelper devscripts dput software-properties-common \
            python3-distutils python3-setuptools python3-wheel python3-stdeb jq fakeroot
python3 -m pip install --upgrade pip setuptools pdm

cd ArchiveBox/
git pull --recurse-submodules

# Build the debian package
./bin/build_deb.sh

docker run -v $PWD:/data -it ubuntu:22.04 /bin/bash -c "dpkg-deb --build archivebox; apt-get update -qq; env DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt install -y ./archivebox.deb"

# Install the built package locally during testing
apt install ./archivebox.deb
# or:
dpkg -i ./archivebox.deb

# Push the Apt/Debian package to the LaunchPad PPA
./bin/release.sh
```

~~To setup your GPG keys for signing the debian package these commands may be helpful:~~
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

docker run -v $PWD:/data ubuntu:latest /bin/bash -c "apt-get update -qq; apt-get install -qq -y devscripts gpg; cd /data; gpg --import public.key; gpg --import private.key; dpkg-source -b archivebox-0.7.1; cd archivebox-0.7.1; dpkg-genchanges --build=source,all -sa > ../archivebox_0.7.1-1_source.changes; cd ..; debsign -k 52423FBED1586F45 ./archivebox_0.7.1-1_source.changes"
```

A full guide for doing Python packaging on Debian with `stdeb` is available here: https://docs.monadical.com/s/BkF2EoKqw


</details>
