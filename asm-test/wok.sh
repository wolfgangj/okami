#!/bin/sh
nasm -f elf64 ../wok-rt.asm -o wok-rt.o || exit 1
as ../os-openbsd.s -o os.o || exit 1
as app.s       -o app.o    || exit 1
ld -o app -nostdlib -pie -static wok-rt.o os.o app.o || exit 1
