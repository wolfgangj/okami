#!/bin/sh
nasm -f elf64 ../wok-rt.asm -o wok-rt.o || exit 1
#as ../os-openbsd.s -o os.o || exit 1
nasm -f elf64 ../os-openbsd.asm -o os.o || exit 1
as app.s       -o app.o    || exit 1

# use the GNU linker b/c the nasm version of the OpenBSD ident section is broken in llvm-ld
ld.bfd -o app -nostdlib -pie -static wok-rt.o os.o app.o || exit 1
