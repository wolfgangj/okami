#!/bin/sh
nasm -f elf64 ../../runtime/wok-rt.asm -o wok-rt.o || exit 1
nasm -f elf64 ../../runtime/os-openbsd.asm -o os.o || exit 1

for f in ok-*.wok; do
    MODULE=$(echo "$f" | sed -e 's/.wok$//')
    ruby ../../wok.rb "$MODULE" >"$MODULE".asm || exit 1
    nasm -f elf64 "$MODULE".asm -o "$MODULE".o || exit 1
    ld.bfd -o "test-$MODULE" -nostdlib -pie -static -z notext wok-rt.o os.o "$MODULE".o || exit 1
    ./test-"$MODULE" || (echo "$f" failed; exit 1)
done
