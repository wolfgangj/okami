#!/bin/sh

OS=$(uname -s | tr '[A-Z]' '[a-z]')
ARCH=$(uname -m)

# special linker flags
if [ "$OS" = openbsd ]; then
    LDFLAGS="-static -pie -z notext"
else
    LDFLAGS="-static"
fi

# alternative architecture names
if [ "$ARCH" = x86_64 ]; then
    ARCH=amd64
fi

nasm -f elf64 -dOS="$OS" okami-"$ARCH".s -o okami.o || exit 1
ld.bfd -o okami -nostdlib $LDFLAGS okami.o || exit 1

if [ "$1" = '-d' ]; then
    # on OpenBSD, egdb is the newer gdb from ports
    if [ "$(which egdb)" = '' ]; then
        gdb okami 3<script.ok
    else
        egdb okami 3<script.ok
    fi
else
    ./okami  3<script.ok
fi
