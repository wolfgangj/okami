#!/bin/sh
OS=$(uname -s | tr '[A-Z]' '[a-z]')
ARCH=$(uname -m)

# special linker flags
if [ $OS = openbsd ]; then
    LDFLAGS="-static -pie -z notext"
else
    LDFLAGS="-static"
fi

# alternative architecture names
if [ $ARCH = x86_64 ]; then
    ARCH=amd64
fi

nasm -f elf64 -dOS=$OS ../../runtime/wok-rt-$ARCH.asm -o wok-rt.o || exit 1

ruby ../../wok.rb welcome >welcome.asm || exit 1
nasm -f elf64 welcome.asm -o welcome.o || exit 1

ld.bfd -o welcome -nostdlib $LDFLAGS wok-rt.o welcome.o || exit 1
