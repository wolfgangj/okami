default rel                             # relative addressing

; syscall ABI:
; call no => rax
; args order => rdi, rsi, rdx, r10, r8, r9
; retval => rax (and rdx)

; from <sys/syscall.h>
%define SYS_exit 1
%define SYS_write 4

; from <sysexits.h>
%define EX_SOFTWARE 70

extern app.new                         ; the wok code entry point

section .rodata

outofbounds_msg:
        db `array index out of bounds\n`
outofbounds_msg_len equ $-outofbounds_msg

section .bss

; rbp is the data stack pointer, the stack is empty and grows downward
data_stack_bottom:
        resw 256
data_stack_top:

orig_rsp:
        resw 1

section .text

global runtime.outofbounds
runtime.outofbounds:
        mov rax, SYS_write
        mov rdi, 1
        lea rsi, [outofbounds_msg]
        mov rdx, outofbounds_msg_len
        syscall
        mov rax, SYS_exit
        mov rdi, EX_SOFTWARE            ; from sysexits.h, internal software error
        syscall

global runtime.syscall3
runtime.syscall3:
        mov rdi, [rbp+8]
        mov rsi, [rbp+16]
        mov rdx, [rbp+24]
        syscall
        add rbp, 24
        ret

global runtime.get_arg
runtime.get_arg:
        mov rbx, [orig_rsp]
        mov rbx, [orig_rsp+8]
        mov rbx, [orig_rsp+16]
        ret

global _start
_start:
        mov [orig_rsp], rsp         ; for access to program args

        lea rbp, [data_stack_top-8] ; initialize data stack
        call app.new                    ; enter application code 

        mov rdi, 0                      ; success
        mov rax, SYS_exit               ; exit syscall
        syscall
