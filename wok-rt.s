.intel_syntax noprefix
# syscall ABI:
# call no => rax
# args order => rdi, rsi, rdx, r10, r8, r9
# retval => rax (and rdx)

# from <sys/syscall.h>
.set SYS_exit, 1
.set SYS_write, 4

# from <sysexits.h>
.set EX_SOFTWARE, 70

.extern app.new                         # the wok code entry point

.section ".note.openbsd.ident", "a"
.align 2
.long 8
.long 4
.long 1
.ascii "OpenBSD\0"
.long 0
.align 2

.section .rodata

out_of_bounds_msg: .ascii "array index out of bounds\n"

.section .bss

# rbp is the data stack pointer, the stack is empty and grows downward
data_stack_bottom: .skip 1024
data_stack_top:

.section .text

.global runtime.out_of_bounds
runtime.out_of_bounds:
        mov rax, SYS_write
        mov rdi, 1
        lea rsi, [rip+out_of_bounds_msg]
        mov rdx, 26                     # TODO: calculate msg len
        syscall
        mov rax, SYS_exit
        mov rdi, EX_SOFTWARE            # from sysexits.h, internal software error
        syscall

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
        lea rbp, [rip+data_stack_top-8] # initialize data stack
        call app.new                    # enter application code 

        mov rdi, 0                      # success
        mov rax, SYS_exit               # exit syscall
        syscall
