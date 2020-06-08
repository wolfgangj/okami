#!/bin/sh
OS=$(uname -s | tr '[A-Z]' '[a-z]')
ARCH=$(uname -m)
# alternative architecture names
if [ $ARCH = x86_64 ]; then
    ARCH=amd64
fi

nasm -f elf64 -DOS=$OS ../../runtime/wok-rt-$ARCH.asm -o wok-rt.o || exit 1
nasm -f elf64 ../../runtime/os-$OS-$ARCH.asm -o os.o || exit 1

ruby ../../wok.rb welcome >welcome.asm || exit 1
nasm -f elf64 welcome.asm -o welcome.o || exit 1

ld.bfd -o welcome -nostdlib -pie -static -z notext wok-rt.o os.o welcome.o || exit 1
