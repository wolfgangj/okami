default rel

extern runtime.syscall3
extern runtime.outofbounds

section .rodata
.L1: db 'hello',10,0

section .text

global app.new
app.new:

mov [rbp], rax
sub rbp, 8
mov rax, 6 ; len of text

mov [rbp], rax
sub rbp, 8
lea rax, [.L1]

mov [rbp], rax
sub rbp, 8
mov rax, 2 ; stdout-fd

mov [rbp], rax
sub rbp, 8
mov rax, 4 ; syscall write

call runtime.syscall3

add rbp, 8 ; drop

call runtime.outofbounds

ret
