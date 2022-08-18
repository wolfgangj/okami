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
; rcx = (unused)
; rdx = (temp)
; rsp = data stack pointer, empty+downward
; rsi = instruction pointer
; rbp = aux stack pointer, empty+downward
; rdi = (unused)
; r8  = (unused)
; r9 = (unused)
; r10 = (unused)
; r11 = (unused)
; r12 = input pointer for reading initial file
; r13 = builtin dict pointer for bootstrapping
; r14 = return stack pointer, empty+downward
; r15 = top of aux stack

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

dict_user:
        times 32 dq 0, 0
dict_start:
        db 'this    '
        dq cf_this
        db 'that    '
        dq cf_that
        db 'alt     '
        dq cf_alt
        db 'drop    '
        dq cf_drop
        db 'nip     '
        dq cf_nip
        db 'tuck    '
        dq cf_tuck
        db 'they    '
        dq cf_they
        db 'word    '
        dq cf_word
        db '+       '
        dq cf_plus
        db '-       '
        dq cf_minus
        db '*       '
        dq cf_mult
        db 'not     '
        dq cf_not
        db 'and     '
        dq cf_and
        db 'or      '
        dq cf_or
        db 'xor     '
        dq cf_xor
        db 'lit     '
        dq cf_lit
        db '@       '
        dq cf_at
        db '!       '
        dq cf_bang
        db '=       '
        dq cf_eq
        db '<>      '
        dq cf_ne
        db '>       '
        dq cf_gt
        db '<       '
        dq cf_lt
        db '>=      '
        dq cf_ge
        dq '<=      '
        dq cf_le
        db '>aux    '
        dq cf_to_aux
        db 'aux>    '
        dq cf_from_aux
        db 'aux!    '
        dq cf_aux_bang
        db 'aux@    '
        dq cf_aux_at
        db 'auxdrop '
        dq cf_auxdrop
        db '>r      '
        dq cf_to_r
        db 'r>      '
        dq cf_from_r
        db 'r@      '
        dq cf_r_at
        db 'rdrop   '
        dq cf_rdrop
        db 'syscall '
        dq cf_syscall
        db 'exit    '
        dq cf_exit
        db 'args    '
        dq cf_args
        db 'env     '
        dq cf_env
        db 'docol,, '
        dq cf_docol_com
        db 'dodoes,,'
        dq cf_dodoes_com
        db 'entry:  '
        dq cf_entry
        db "'       "
        dq cf_quote
dict_end:
        db '        '           ; will be overwritten
        dq 0

cf_exit:        dq op_exit
cf_this:        dq op_this
cf_that:        dq op_that
cf_alt:         dq op_alt
cf_drop:        dq op_drop
cf_nip:         dq op_nip
cf_tuck:        dq op_tuck
cf_they:        dq op_they
cf_word:        dq op_word
cf_lit:         dq op_lit
cf_plus:        dq op_plus
cf_minus:       dq op_minus
cf_mult         dq op_mult
cf_not:         dq op_not
cf_eq:          dq op_eq
cf_ne:          dq op_ne
cf_lt:          dq op_lt
cf_gt:          dq op_gt
cf_le:          dq op_le
cf_ge:          dq op_ge
cf_to_aux:      dq op_to_aux
cf_from_aux:    dq op_to_aux
cf_aux_bang:    dq op_aux_bang
cf_aux_at:      dq op_aux_at
cf_auxdrop:     dq op_auxdrop
cf_to_r:        dq op_to_r
cf_from_r:      dq op_from_r
cf_r_at:        dq op_r_at
cf_rdrop:       dq op_rdrop
cf_syscall:     dq op_syscall
cf_args:        dq op_args
cf_env:         dq op_env
cf_bang:        dq op_bang
cf_and:         dq op_and
cf_or:          dq op_or
cf_xor:         dq op_xor
cf_at:          dq op_at
cf_docol_com:   dq op_docol_com
cf_dodoes_com:  dq op_dodoes_com
cf_entry:       dq op_entry
cf_quote:       dq op_quote

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
        mov [r14], %1
        lea r14, [r14 - 8]
%endmacro

%macro rpop 1
        lea r14, [r14 + 8]
        mov %1, [r14]
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

op_this:
        push rbx
        next

op_that:
        push rbx
        mov rbx, [rsp+8]
        next

op_alt:
        mov rdx, [rsp]
        mov [rsp], rbx
        mov rbx, rdx
        next

op_drop:
        pop rbx
        next

op_nip:
        lea rsp, [rsp + 8]
        next

op_tuck:
        mov rdx, [rsp]
        mov [rsp], rbx
        push rdx
        next

op_they:
        mov rdx, [rsp]
        push rbx
        push rdx
        next

op_to_aux:
        mov [rbp], r15
        lea rbp, [rbp - 8]
        mov r15, rbx
        pop rbx
        next

op_from_aux:
        push rbx
        mov rbx, r15
        lea rbp, [rbp + 8]
        mov r15, [rbp]
        next

op_aux_bang:
        mov r15, rbx
        pop rbx
        next

op_aux_at:
        push rbx
        mov rbx, r15
        next

op_auxdrop:
        lea rbp, [rbp + 8]
        mov r15, [rbp]
        next

op_to_r:
        rpush rbx
        pop rbx
        next

op_from_r:
        push rbx
        rpop rbx
        next

op_r_at:
        push rbx
        mov rbx, [r14 + 8]
        next

op_rdrop:
        lea r14, [rsp + 8]
        next

op_word:
        push rbx
        mov ebx, 8
        next

op_lit:
        push rbx
        lodsq                   ; rax = [rsi], rsi += 8
        mov rbx, rax
        next

op_at:
        mov rbx, [rbx]
        next

op_bang:
        pop rdx
        mov [rbx], rdx
        pop rbx
        next

op_plus:
        pop rdx
        add rbx, rdx
        next

op_minus:
        pop rdx
        sub rdx, rbx
        mov rbx, rdx
        next

op_mult:
        pop rdx
        imul rbx, rdx
        next

op_not:
        not rbx
        next

op_and:
        pop rdx
        and rbx, rdx
        next

op_or:
        pop rdx
        or rbx, rdx
        next

op_xor:
        pop rdx
        xor rbx, rdx
        next

op_eq:
        pop rax
        cmp rbx, rax
        setne dl
        movzx rbx, dl
        dec rbx
        next

op_ne:
        pop rax
        cmp rbx, rax
        sete dl
        movzx rbx, dl
        dec rbx
        next

op_lt:
        pop rax
        cmp rbx, rax
        setge dl
        movzx rbx, dl
        dec rbx
        next

op_gt:
        pop rax
        cmp rbx, rax
        setle dl
        movzx rbx, dl
        dec rbx
        next

op_le:
        pop rax
        cmp rbx, rax
        setg dl
        movzx rbx, dl
        dec rbx
        next

op_ge:
        pop rax
        cmp rbx, rax
        setl dl
        movzx rbx, dl
        dec rbx
        next

op_equal:
        pop rdx
        mov rax, rbx
        xor ebx, ebx
        cmp rax, rdx
        je op_not
        next

op_not_equal:
        pop rdx
        mov rax, rbx
        xor ebx, ebx
        cmp rax, rdx
        jne op_not
        next

true:
        xor ebx, ebx
        not rbx
        next

op_docol_com:
        mov QWORD [rbx], docol
        add rbx, 8
        next

op_dodoes_com:
        mov QWORD [rbx], dodoes
        add rbx, 8
        next

op_quote:
        push rbx
        read_word
        call find_word
        mov rbx, [rax]
        next

; this always takes 7 args
op_syscall:
        rpush rsi
        mov rax, rbx
        pop r9
        pop r8
        pop r10
        pop rdx
        pop rsi
        pop rdi
        syscall
        rpop rsi
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

op_entry:
        read_word
        sub r13, 16
        mov [r13], rax
        mov [r13 + 8], rbx
        next

; find word from rax in dict, return in rax
; on failure, [rax] will be 0
find_word:
        mov [dict_end], rax             ; ensure we always exit
        lea rdx, [dict_user]
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

        lea r14, [return_stack_top-8]   ; initialize return stack
        lea rsi, [aux_stack_top-8]      ; initialize aux stack

        lea rbx, [dataspace]            ; initial stack value
        lea r13, [dict_start]           ; initial dictionary

interpret:
        read_word
        call find_word
        ;; set up registers for docol/dodoes and make a setup so that
        ;; we return to 'interpret' afterwards:
        lea rsi, [code_interpret]
        mov rax, [rax]
        jmp [rax]
