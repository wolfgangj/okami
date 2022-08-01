; okami-amd64.s - x86-64 version of the okami engine (virtual machine)
; originally based on the runtime of wok and the AArch32 version of okami
; Copyright (C) 2018, 2019, 2020, 2022 Wolfgang Jährling
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
; rax = (temp), next leaves CFA here
; rbx = top of data stack
; rcx = return stack pointer, empty+downward
; rdx = (temp)
; rsp = aux stack pointer, empty+downward
; rsi = instruction pointer
; rbp = data stack pointer, empty+downward
; rdi = top of aux stack
; r8  = (temp)
; r9 - r11 = ?
; r12 = input pointer for reading initial file
; r13 - r15 = ?

; syscall ABI:
; call no => rax
; args order => rdi, rsi, rdx, r10, r8, r9
; retval => rax (and rdx), rcx and r11 are clobbered

%ifidn OS,openbsd
section .note.openbsd.ident note
    align 2
    dd 8,4,1
    db "OpenBSD",0
    dd 0
%endif

;; =====================================
;; system constants
%ifidn OS,openbsd
; from <sys/syscall.h>
%define SYS_mmap 49
; from <sys/mman.h>
%define PROT_READ 1
%define MAP_PRIVATE 2

%elifidn OS,linux
; from <sys/syscall.h>
%define SYS_mmap 9
; from <sys/mman.h>
%define PROT_READ 1
%define MAP_PRIVATE 2

%else
%fatal unknown operating system: OS
%endif

;; =====================================
section .data

dict_userdefined:
        times 32 dq 0, 0
dict_start:
        db 'syscall '
        dq cf_syscall
        db 'exit    '
        dq cf_exit
        db 'args    '
        dq cf_args
        db 'env     '
        dq cf_env
dict_end:
        db '        '           ; will be overwritten
        dq 0

dict_pointer:
        dq dict_start

cf_syscall:   dq op_syscall
cf_exit:      dq op_exit
cf_args:      dq op_args
cf_env:       dq op_env

; the "next instruction" location when interpreting:
code_interpret: dq cf_interpret
cf_interpret: dq interpret

;; =====================================
section .bss

return_stack_bottom:
        resq 64
return_stack_top:

aux_stack_bottom:
        resq 32
aux_stack_top:

orig_rsp:
        resq 1

dataspace:
        resb 1024 * 32          ; 32k

;; =====================================
section .text

%macro next 0
        lodsq                   ; rax = [rsi], rsi += 8
        jmp [rax]               ; get code field value
%endmacro

%macro rpush 1
        mov [rcx], %1
        lea rcx, [rcx - 8]
%endmacro

%macro rpop 1
        lea rcx, [rcx + 8]
        mov %1, [rcx]
%endmacro

; read a word from input buffer into rax, names must be 8 bytes.
%macro read_word 0
        mov rax, [r12]
        lea r12, [r12 + 8]
%endmacro

dodoes:
        ;; 'next' leaves the CFA in rax
        push rbx
        lea rbx, [rax + 16]     ; put CFA+(2 words) in tos
        ;; push ip on rs and set up new ip as CFA+(1 word)
        rpush rsi
        mov rsi, [rax + 8]
        next

docol:
        ;; push ip on rs
        rpush rsi
        ;; set up new ip
        lea rsi, [rax + 8]
        next

op_exit:
        rpop rsi
        next

; this always takes 7 args
op_syscall:
        rpush rcx
        rpush rdi
        rpush rsi
        mov rax, rbx
        pop rdi
        pop rsi
        pop rdx
        pop r10
        pop r8
        pop r9
        syscall
        rpop rsi
        rpop rdi
        rpop rcx
        mov rbx, rax
        next

op_args:
        push rbx
        mov rbx, [orig_rsp]
        add rbx, 8
        next

op_env:
        push rbx
        mov rax, [orig_rsp]
        mov rdx, [rax]
        lea rbx, [rax+rdx*8+16]
        next

; find word from rax in dict, return in rax
; on failure, [rax] will be 0
find_word:
        mov [dict_end], rax             ; ensure we always exit
        mov rdx, [dict_pointer]
find_word_loop:
        cmp rax, [rdx]
        je find_word_done
        lea rdx, [rdx + 16]
        jmp find_word_loop
find_word_done:
        lea rax, [rdx + 8]
        ret

global _start
_start:
        mov [orig_rsp], rsp     ; for access to cmdline args / env

        ;; load input file
        mov rax, SYS_mmap
        xor rdi, rdi            ; addr = 0
        mov esi, 1024 * 32      ; len = 32k
        mov edx, PROT_READ      ; prot
        mov r10, MAP_PRIVATE    ; flags
        mov r8d, 3              ; fd
        xor r9d, r9d            ; offset = 0
        syscall
        mov r12, rax            ; set up input buffer pointer

        lea rcx, [return_stack_top-8]   ; initialize return stack
        lea rsi, [aux_stack_top-8]      ; initialize aux stack

        lea rbx, [dataspace]

interpret:
        read_word
        call find_word
        ;; set up registers for docol/dodoes and make a setup so that
        ;; we return to 'interpret' afterwards:
        lea rsi, [code_interpret]
        mov rax, [rax]
        jmp [rax]
