#!/bin/sh

set -e

inst()
{
    sudo apt install -y "$@"
}

log()
{
    echo "`date +%Y.%m.%d-%H-%M:%S`" "$@"
}

fetch()
{
    wget -nc "$@"
}

extract()
{
    tar -xvf "$@"
}

minstall()
{
    sudo make install
}

install_and_mark()
{
    if [ -z "$1" ]; then
        log "wrong params for install_and_mark"
        exit 1
    fi
    minstall
    cd ..
    touch "$1.done"
}

already_done()
{
    if [ -z "$1" ]; then
        log "wrong params for already_done"
        exit 1
    fi

    if [ -r "$1.done" ]; then
        log "$1 already done, skipping build."
        return 0
    else
        log "building $1"
        return 1
    fi
}

prepare_source_from_http()
{
    dir="$1"
	shift;
	tar="$1"
    shift;
    url="$1"
    shift
	log "fetching $dir from http: $url"

    if [ -z "$dir" ] || [ -z "$tar" ] || [ -z "$url" ]; then
        log "wrong params for prepare_source_from_http"
        exit 1
    fi

    fetch "$url"
	if ! [ -d "${dir}" ]; then
    	extract "$tar"
	else
    	log "${dir} already exists, skipping extract operation"
	fi
	cd "$dir"
}

prepare_source_from_git()
{
    dir="$1"
    shift;
    url="$1"
    shift
	log "fetching $dir from git: $url"

    if [ -z "$dir" ] || [ -z "$url" ]; then
        log "wrong params for prepare_source_from_git"
        exit 1
    fi

    if ! [ -d "${dir}" ]; then
		git clone "$url"
    else
        log "${dir} already exists, skipping clone operation"
    fi
    cd "$dir"
}

inst git
inst g++
inst libtool automake
inst wget

# root directory for all stuff

build_dir="."

libs_dir="$build_dir/Libraries"
repo_dir="$build_dir/tdesktop"

log "creating directories"
mkdir -p "$libs_dir"

cd "$build_dir"
log "Cloning TelegramDesktop from GitHub"
if ! [ -d "$repo_dir" ]; then
    git clone --recursive https://github.com/telegramdesktop/tdesktop.git
else:
    log "tdesktop repo already exists, skipping clone"
fi

inst libexif-dev liblzma-dev libz-dev libssl-dev libappindicator-dev libunity-dev libicu-dev libdee-dev

cd "$libs_dir"

if ! already_done zlib; then

    zlib_ver="zlib-1.2.11"
    zlib_tar="${zlib_ver}.tar.gz"
    prepare_source_from_http "${zlib_ver}" "${zlib_tar}" "http://www.zlib.net/${zlib_tar}"

    ./configure
    make
    install_and_mark zlib
fi

if ! already_done opus; then
    prepare_source_from_git "opus" "https://github.com/xiph/opus"

    # here was tag v1.2-alpha2, but we'll use rc1
    git checkout "v1.2-rc1"
    ./autogen.sh
    ./configure
    make
    install_and_mark opus
fi

