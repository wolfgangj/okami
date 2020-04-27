.intel_syntax noprefix
.extern runtime.out_of_bounds

# stuff included with 'use'
.extern runtime.syscall3

.section .rodata
.L1: .asciz "hello\n"

.section .text
.global app.new
app.new:
        mov [rbp], rax                  # push 1
        sub rbp, 8                      # push 2
        mov rax, 6                      # len of text

        mov [rbp], rax                  # push 1
        sub rbp, 8                      # push 2
        lea rax, [rip+.L1]              # adr of text

        mov [rbp], rax                  # push 1
        sub rbp, 8                      # push 2
        mov rax, 2                      # stderr-fd

        mov [rbp], rax                  # push 1
        sub rbp, 8                      # push 2
        mov rax, 4                      # write

        call runtime.syscall3

        add rbp, 8                      # drop

        call runtime.outofbounds

        ret
