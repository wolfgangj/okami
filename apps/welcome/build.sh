#!/bin/sh
nasm -f elf64 ../../runtime/wok-rt.asm -o wok-rt.o || exit 1
nasm -f elf64 ../../runtime/os-openbsd.asm -o os.o || exit 1

ruby ../../wok.rb welcome >welcome.asm || exit 1
nasm -f elf64 welcome.asm -o welcome.o || exit 1

ld.bfd -o welcome -nostdlib -pie -static -z notext wok-rt.o os.o welcome.o || exit 1
