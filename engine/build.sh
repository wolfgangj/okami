#!/bin/sh

OS=$(uname -s | tr '[A-Z]' '[a-z]')
ARCH=$(uname -m)

# special linker flags
if [ "$OS" = openbsd ]; then
    #LDFLAGS="-static -pie -z notext"
    LDFLAGS="-static -nopie"
else
    LDFLAGS="-static"
fi

# alternative architecture names
if [ "$ARCH" = x86_64 ]; then
    ARCH=amd64
fi

echo "OS:      $OS"
echo "ARCH:    $ARCH"
echo "LDFLAGS: $LDFLAGS"

nasm -f elf64 -g -dOS="$OS" okami-"$ARCH".s -o okami.o || exit 1
ld -o okami -nostdlib $LDFLAGS okami.o || exit 1
#ld.bfd -o okami -nostdlib $LDFLAGS okami.o || exit 1

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
