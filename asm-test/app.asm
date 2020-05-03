default rel

extern runtime.outofbounds

extern runtime.syscall
extern runtime.getarg

section .rodata
.L1: db 'hello',10,0

section .text

global app._size
app._size equ 16 ; how large an instance is

global app.new
app.new:

mov [rbp], rax
sub rbp, 8
mov rax, 2 ; stdout-fd

mov [rbp], rax
sub rbp, 8
lea rax, [.L1]

mov [rbp], rax
sub rbp, 8
mov rax, 6 ; len of text

; fill remaining args
mov [rbp], rax
sub rbp, 8
mov rax, 0
mov [rbp], rax
sub rbp, 8
mov rax, 0
mov [rbp], rax
sub rbp, 8
mov rax, 0

mov [rbp], rax
sub rbp, 8
mov rax, 4 ; syscall write

call runtime.syscall

call runtime.outofbounds

ret
