%include "../runtime/wok-codes.asm"

; included via runtime.wok
extern runtime.syscall
extern runtime.getarg
extern runtime.outofbounds ; duplicate

section .rodata
L0: db 'hello',10,0

section .text

; class:
global app._size
app._size equ 16 ; how large an instance is
app.new:

global run
run:

mov [rbp], rax
sub rbp, 8
mov rax, 2 ; stdout-fd

mov [rbp], rax
sub rbp, 8
lea rax, [L0]

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

; test of wok-codes
wok_drop
wok_nip
wok_this
wok_that
wok_them
wok_alt
wok_tuck
wok_dropem
wok_method_call app.new
wok_self
wok_attr_access 8
wok_add
wok_sub
wok_mul
wok_div
wok_mod
wok_not
wok_and
wok_or
wok_xor
wok_ashift_right
wok_shift_right
wok_shift_left
wok_idx 10, 8
wok_if_check L1
wok_if_end L1
wok_eif_check L2
wok_eif_else L3, L2
wok_eif_end L3
wok_ehas_check L4
wok_ehas_else L5, L4
wok_ehas_end L5
wok_loop_start L6
wok_break L7
wok_loop_end L6, L7
wok_new_start app
wok_new_end
