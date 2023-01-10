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

%macro entry 2
        db %1
        dq cf_%2
%endmacro

dict_user:
        times 128 dq 0, 0
dict_start:
        entry 'this    ', this
        entry 'that    ', that
        entry 'alt     ', alt
        entry 'drop    ', drop
        entry 'nip     ', nip
        entry 'tuck    ', tuck
        entry 'they    ', they
        entry 'dropem  ', dropem
        entry 'cell    ', cell
        entry '+       ', plus
        entry '-       ', minus
        entry '*       ', mult
        entry '/mod    ', divmod
        entry 'not     ', not
        entry 'and     ', and
        entry 'or      ', or
        entry 'xor     ', xor
        entry 'lit     ', lit
        entry '@       ', at
        entry '!       ', bang
        entry 'branch  ', branch
        entry 'branch0 ', branch0
        entry '=       ', eq
        entry '<>      ', ne
        entry '>       ', gt
        entry '<       ', lt
        entry '>=      ', ge
        entry '<=      ', le
        entry '>aux    ', to_aux
        entry 'aux>    ', from_aux
        entry 'aux!    ', aux_bang
        entry 'aux@    ', aux_at
        entry 'auxdrop ', auxdrop
        entry '>r      ', to_r
        entry 'r>      ', from_r
        entry 'r@      ', r_at
        entry 'rdrop   ', rdrop
        entry 'syscall ', syscall
        entry 'execute ', execute
        entry 'i8!     ', i8bang
        entry 'i8@     ', i8at
        entry 'u8@     ', u8at
        entry 'i16!    ', i16bang
        entry 'i16@    ', i16at
        entry 'u16@    ', u16at
        entry 'i32!    ', i32bang
        entry 'i32@    ', i32at
        entry 'u32@    ', u32at
        entry 'exit    ', exit
        entry 'args    ', args
        entry 'env     ', env
        entry 'docol   ', docol
        entry 'dodoes  ', dodoes
        entry 'dopush  ', dopush
        entry 'entry:  ', entry
        entry "'       ", quote
dict_end:
        db '        '           ; will be overwritten
        dq 0

%define cf(o) cf_ %+ o: dq op_ %+ o
cf(exit)
cf(this)
cf(that)
cf(alt)
cf(drop)
cf(nip)
cf(tuck)
cf(they)
cf(dropem)
cf(cell)
cf(lit)
cf(branch)
cf(branch0)
cf(plus)
cf(minus)
cf(mult)
cf(divmod)
cf(not)
cf(eq)
cf(ne)
cf(lt)
cf(gt)
cf(le)
cf(ge)
cf(to_aux)
cf(from_aux)
cf(aux_bang)
cf(aux_at)
cf(auxdrop)
cf(to_r)
cf(from_r)
cf(r_at)
cf(rdrop)
cf(syscall)
cf(execute)
cf(at)
cf(bang)
cf(and)
cf(or)
cf(xor)
cf(i8bang)
cf(i8at)
cf(u8at)
cf(i16bang)
cf(i16at)
cf(u16at)
cf(i32bang)
cf(i32at)
cf(u32at)
cf(entry)
cf(quote)
cf(args)
cf(env)

; the "next instruction" location when interpreting:
code_interpret: dq cf_interpret
cf(interpret)

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

;; dodoes, docol and dopush do not need a separate code field, as they are
;; inserted into the code field of the definitions that they are used for.
cf_dodoes:
        ;; 'next' leaves the CFA in rax
        push rbx
        lea rbx, [rax + 16]     ; put CFA+(2 words) in tos
        ;; push ip on rs and set up new ip as CFA+(1 word)
        rpush rsi
        mov rsi, [rax + 8]
        next

cf_docol:
        ;; push ip on rs
        rpush rsi
        ;; set up new ip
        lea rsi, [rax + 8]
        next

cf_dopush:
        push rbx
        lea rbx, [rax + 8]
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

op_dropem:
        mov rbx, [rsp + 8]
        lea rsp, [rsp + 16]
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

op_cell:
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

op_branch:
        mov rsi, [rsi]
        next

op_branch0:
        lea rsi, [rsi + 8]   ; for case of non-zero: skip target address
        test rbx, rbx
        cmovz rsi, [rsi - 8]
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

op_divmod:
        pop rax
        xor rdx, rdx
        idiv rbx
        push rdx
        mov rbx, rax
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

op_execute:
        mov rax, rbx
        pop rbx
        jmp [rax]

op_i8bang:
        pop rdx
        mov [rbx], dl
        pop rbx
        next

op_i8at:
        movsx rbx, byte [rbx]
        next

op_u8at:
        mov rdx, rbx
        xor ebx, ebx
        mov bl, [rdx]
        next

op_i16bang:
        pop rdx
        mov [rbx], dx
        pop rbx
        next

op_i16at:
        movsx rbx, word [rbx]
        next

op_u16at:
        mov rdx, rbx
        xor ebx, ebx
        mov bx, [rdx]
        next

op_i32bang:
        pop rdx
        mov [rbx], edx
        pop rbx
        next

op_i32at:
        movsx rbx, dword [rbx]
        next

op_u32at:
        mov ebx, [rbx]
        next

op_args:
        push rbx
        mov rbx, [orig_rsp]
        lea rbx, [rbx + 8]
        next

op_env:
        push rbx
        mov rax, [orig_rsp]
        mov rdx, [rax]
        lea rbx, [rax+rdx*8+16]
        next

op_entry:
        read_word
        lea r13, [r13 - 16]
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
        lea rbp, [aux_stack_top-8]      ; initialize aux stack

        lea rbx, [dataspace]            ; initial stack value
        lea r13, [dict_start]           ; initial dictionary

op_interpret:
        read_word
        call find_word
        ;; set up registers for docol/dodoes and make a setup so that
        ;; we return to op_interpret afterwards:
        lea rsi, [code_interpret]
        mov rax, [rax]
        jmp [rax]
