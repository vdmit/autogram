#!/bin/sh

# all-in-one Telegram Desktop build script for Linux
# Tested on Ubuntu series (16.04 LTS)

# (c) 2017 Dmitry Veltishchev <dm.velt@ya.ru> (github:vdmit)
# See LICENSE.md for legal info

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
	log "leaving $(basename `pwd`)"
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

    if ! [ -d "$dir" ]; then
		git clone "$url" "$dir"
    else
        log "$dir already exists, skipping clone operation"
    fi
	log "entering $dir"
    cd "$dir"
}

inst git
inst g++
inst libtool automake autoconf build-essential
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

log "building FFmpeg and Co."

if ! already_done libva; then
    prepare_source_from_git "libva" "https://github.com/01org/libva.git"

	./autogen.sh --enable-static
	make
	install_and_mark libva
fi

if ! already_done libvdpau; then
    prepare_source_from_git "libvdpau" "git://anongit.freedesktop.org/vdpau/libvdpau"
	./autogen.sh --enable-static
	make
	install_and_mark libvdpau
fi

if ! already_done ffmpeg; then
	prepare_source_from_git ffmpeg "https://github.com/FFmpeg/FFmpeg.git" ffmpeg
	git checkout "release/3.2"

	inst libass-dev libfreetype6-dev libgpac-dev libsdl1.2-dev libtheora-dev libva-dev libvdpau-dev libvorbis-dev libxcb1-dev libxcb-shm0-dev libxcb-xfixes0-dev pkg-config texi2html zlib1g-dev
	inst yasm

	./configure --prefix=/usr/local --disable-programs --disable-doc --disable-everything --enable-protocol=file --enable-libopus --enable-decoder=aac --enable-decoder=aac_latm --enable-decoder=aasc --enable-decoder=flac --enable-decoder=gif --enable-decoder=h264 --enable-decoder=h264_vdpau --enable-decoder=mp1 --enable-decoder=mp1float --enable-decoder=mp2 --enable-decoder=mp2float --enable-decoder=mp3 --enable-decoder=mp3adu --enable-decoder=mp3adufloat --enable-decoder=mp3float --enable-decoder=mp3on4 --enable-decoder=mp3on4float --enable-decoder=mpeg4 --enable-decoder=mpeg4_vdpau --enable-decoder=msmpeg4v2 --enable-decoder=msmpeg4v3 --enable-decoder=opus --enable-decoder=pcm_alaw --enable-decoder=pcm_alaw_at --enable-decoder=pcm_f32be --enable-decoder=pcm_f32le --enable-decoder=pcm_f64be --enable-decoder=pcm_f64le --enable-decoder=pcm_lxf --enable-decoder=pcm_mulaw --enable-decoder=pcm_mulaw_at --enable-decoder=pcm_s16be --enable-decoder=pcm_s16be_planar --enable-decoder=pcm_s16le --enable-decoder=pcm_s16le_planar --enable-decoder=pcm_s24be --enable-decoder=pcm_s24daud --enable-decoder=pcm_s24le --enable-decoder=pcm_s24le_planar --enable-decoder=pcm_s32be --enable-decoder=pcm_s32le --enable-decoder=pcm_s32le_planar --enable-decoder=pcm_s64be --enable-decoder=pcm_s64le --enable-decoder=pcm_s8 --enable-decoder=pcm_s8_planar --enable-decoder=pcm_u16be --enable-decoder=pcm_u16le --enable-decoder=pcm_u24be --enable-decoder=pcm_u24le --enable-decoder=pcm_u32be --enable-decoder=pcm_u32le --enable-decoder=pcm_u8 --enable-decoder=pcm_zork --enable-decoder=vorbis --enable-decoder=wavpack --enable-decoder=wmalossless --enable-decoder=wmapro --enable-decoder=wmav1 --enable-decoder=wmav2 --enable-decoder=wmavoice --enable-encoder=libopus --enable-hwaccel=h264_vaapi --enable-hwaccel=h264_vdpau --enable-hwaccel=mpeg4_vaapi --enable-hwaccel=mpeg4_vdpau --enable-parser=aac --enable-parser=aac_latm --enable-parser=flac --enable-parser=h264 --enable-parser=mpeg4video --enable-parser=mpegaudio --enable-parser=opus --enable-parser=vorbis --enable-demuxer=aac --enable-demuxer=flac --enable-demuxer=gif --enable-demuxer=h264 --enable-demuxer=mov --enable-demuxer=mp3 --enable-demuxer=ogg --enable-demuxer=wav --enable-muxer=ogg --enable-muxer=opus

	make
	install_and_mark ffmpeg
fi

