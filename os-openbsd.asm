; for some reason, the nasm version only works with the GNU linker (ld.bfd)

section .note.openbsd.ident progbits alloc noexec nowrite
    align 2
    dd 8,4,1
    db "OpenBSD",0
    dd 0
