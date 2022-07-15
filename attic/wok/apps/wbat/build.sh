#!/bin/sh
nasm -f elf64 -dOS=openbsd ../../runtime/wok-rt-amd64.asm -o wok-rt.o || exit 1

ruby ../../wok.rb wbat >wbat.asm || exit 1
nasm -f elf64 wbat.asm -o wbat.o || exit 1

ld.bfd -o wbat -nostdlib -pie -static -z notext wok-rt.o wbat.o || exit 1
