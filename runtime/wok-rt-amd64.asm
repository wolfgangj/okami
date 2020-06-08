; wok-rt.asm - x86-64 version of the runtime library
; Copyright (C) 2019, 2020 Wolfgang Jährling
;
; ISC License
;
; Permission to use, copy, modify, and/or distribute this software for any
; purpose with or without fee is hereby granted, provided that the above
; copyright notice and this permission notice appear in all copies.
;
; THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
; WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
; MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
; ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
; WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
; ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
; OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

; our ABI:
; rax = top of data stack
; rbx = ?
; rcx = (temp)
; rdx = (temp)
; rsp = call stack pointer
; rsi = object stack pointer
; rbp = data stack pointer
; rdi = top of object stack
; r8 - r15 = ?

; syscall ABI:
; call no => rax
; args order => rdi, rsi, rdx, r10, r8, r9
; retval => rax (and rdx)

%ifidn OS,openbsd
; OpenBSD wants position-independent code
default rel
%endif

; from <sys/syscall.h>
%ifidn OS,openbsd
%define SYS_exit 1
%define SYS_write 4

%elifidn OS,linux
%define SYS_exit 60
%define SYS_write 1

%endif

; from <sysexits.h>
%define EX_SOFTWARE 70

extern run                       ; the wok code entry point

section .rodata

outofbounds_msg:
        db `array index out of bounds\n`
outofbounds_msg_len equ $-outofbounds_msg

section .bss

; the stacks are empty / downward growing

; rbp is the data stack pointer, rax is top of data stack
data_stack_bottom:
        resq 64
data_stack_top:

; rsi is the object stack pointer, rdi is top of object stack
obj_stack_bottom:
        resq 32
obj_stack_top:

orig_rsp:
        resq 1

section .text

global rt__outofbounds
rt__outofbounds:
        mov rax, SYS_write
        mov rdi, 1
        lea rsi, [outofbounds_msg]
        mov rdx, outofbounds_msg_len
        syscall
        mov rax, SYS_exit
        mov rdi, EX_SOFTWARE            ; from sysexits.h, internal software error
        syscall

; this always takes 7 args
; example: def write (fd @char int :: int) [0 0 0 SYS_write runtime.syscall]
global rt__syscall
rt__syscall:
        push rsi
        push rdi
        push rbp
        ; no need to save rax, rsp and the temp registers
        mov rdi, [rbp+48]
        mov rsi, [rbp+40]
        mov rdx, [rbp+32]
        mov r10, [rbp+24]
        mov r8,  [rbp+16]
        mov r9,  [rbp+8]
        syscall
        pop rbp
        pop rdi
        pop rsi
        add rbp, 48
        ret

global rt__args
rt__args:
        mov [rbp], rax
        sub rbp, 8
        mov rax, [orig_rsp]
        add rax, 8
        ret

global rt__env
rt__env:
        mov [rbp], rax
        sub rbp, 8
        mov rax, [orig_rsp]
        mov rdx, [rax]
        lea rax, [rax+rdx*8+16]
        ret

global _start
_start:
        mov [orig_rsp], rsp             ; for access to program args
        lea rbp, [data_stack_top-8]     ; initialize data stack
        lea rsi, [obj_stack_top-8]      ; initialize object stack

        call run                        ; enter application code 

        xor edi, edi                    ; success
        mov rax, SYS_exit               ; exit syscall
        syscall
