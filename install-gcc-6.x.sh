#!/bin/sh

# complimentary script for Telegram Desktop build:
# upgrade GCC to version 6.x

# (c) 2017 Dmitry Veltishchev <dm.velt@ya.ru> (github:vdmit)
# See LICENSE.md for legal info


# WARNING: this script changes your default GCC compiler.

set -e

inst()
{
    sudo apt install -y "$@"
}

log()
{
    echo "`date +%Y.%m.%d-%H-%M:%S`" "$@"
}


log "adding test toolchain repo"
sudo add-apt-repository "ppa:ubuntu-toolchain-r/test"
sudo apt update
inst gcc-6 g++-6
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-6 60
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-6 60

log "Checking for GCC version"
gcc -dumpversion

