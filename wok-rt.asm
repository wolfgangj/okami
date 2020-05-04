default rel                             # relative addressing

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

; from <sys/syscall.h>
%define SYS_exit 1
%define SYS_write 4

; from <sysexits.h>
%define EX_SOFTWARE 70

extern app.new                         ; the wok code entry point
extern app._size                       ; size of app instance

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

; this always takes 7 args
; example: def write (fd @char int :: int) [0 0 0 SYS_write runtime.syscall]
global runtime.syscall
runtime.syscall:
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

global runtime.getarg
runtime.getarg:
        inc rax
        mov rdx, [orig_rsp]
        mov rcx, [rdx]
        cmp rax, rcx            ; check if rax is in 1..n
        ja no_arg_left
        mov rax, [rdx+rax*8]
        ret
no_arg_left:
        xor rax, rax
        ret

global _start
_start:
        mov [orig_rsp], rsp             ; for access to program args

        lea rbp, [data_stack_top-8]     ; initialize data stack

        lea rsi, [obj_stack_top-8]      ; initialize object stack

        mov rax, app._size              ; load size of app object
        sub rsp, rax                    ; create space for app object
        mov rdi, rsp                    ; object tos = app

        call app.new                    ; enter application code 

        xor edi, edi                    ; success
        mov rax, SYS_exit               ; exit syscall
        syscall
