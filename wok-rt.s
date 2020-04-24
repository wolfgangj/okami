.intel_syntax noprefix
# syscall ABI:
# call no => rax
# args order => rdi, rsi, rdx, r10, r8, r9
# retval => rax (and rdx)

.extern app.new

.section ".note.openbsd.ident", "a"
.align 2
.long 8
.long 4
.long 1
.ascii "OpenBSD\0"
.long 0
.align 2

.section .rodata

what_to_say: .ascii "Wok\n"

.section .data

# rbp is the data stack pointer, the stack is empty and grows downward
data_stack_bottom: .space 1024
data_stack_top:

.section .text

.global runtime.syscall3
runtime.syscall3:
        mov rdi, [rbp+8]
        mov rsi, [rbp+16]
        mov rdx, [rbp+24]
        syscall
        add rbp, 24
        ret

.global _start
_start:
        mov rax, 4
        mov rdi, 1
        lea rsi, [rip+what_to_say]
        mov rdx, 4
        syscall

        lea rbp, [rip+data_stack_top-8] # initialize data stack
        call app.new                    # enter application code 

        mov rdi, 0                      # success
        mov rax, 1                      # exit syscall
        syscall
