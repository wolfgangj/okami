#!/bin/sh
as ../wok-rt.s -o wok-rt.o || exit 1
as app.s       -o app.o    || exit 1
ld -o app -nostdlib -pie -static wok-rt.o app.o || exit 1
