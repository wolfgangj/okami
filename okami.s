@ okami.s - the beginnings of a programming language project
@ Copyright (C) 2018 Wolfgang Jaehrling
@
@ ISC License
@
@ Permission to use, copy, modify, and/or distribute this software for any
@ purpose with or without fee is hereby granted, provided that the above
@ copyright notice and this permission notice appear in all copies.
@ 
@ THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
@ WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
@ MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
@ ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
@ WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
@ ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
@ OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

@ registers:
@ r0    - tos
@ r1-r7 - scratch (caller saved)
@ r8-r9 - callee saved (r9 currently unused)
@ r10   - ip
@ r11   - trs
@ r12   - rsp, full+downward
@ r13   - sp, full+downward
@ r14   - ARM lr
@ r15   - ARM ip

.equ syscallid_exit, 1
.equ syscallid_read, 3
.equ syscallid_write, 4
.equ fd_stdin, 0
.equ fd_stdout, 1
.equ ioctl_TCGETS, 0x5401

.equ io_bufsize, 4096
.equ max_wordsize, 32

.bss
  return_stack:
    .space 120  @ 30 items deep
  return_stack_bottom:
    .space 8   @ for safety; TODO: should this be `quit` maybe?

    .align 4   @ for whatever reason, it wasn't aligned otherwise
  word_scratch:
    .space max_wordsize

  state:
    .space 4

  input_buffer:
    .space io_bufsize
  input_pos:
    .space 4
  input_end:
    .space 4

  output_buffer:
    .space io_bufsize
  output_buffer_end:
    @ here goes nothing
.data
  output_pos:
    .word output_buffer

  builtin_dictionary:
    @ CFA, zero-terminated string, length of string in words
    .align 4
    .word dup
    .asciz "dup"
    .align 4
    .word 1
    .word drop
    .asciz "drop"
    .align 4
    .word 2
    .word lit
    .asciz "lit"
    .align 4
    .word 1
    .word syscall1
    .asciz "syscall1"
    .align 4
    .word 3
    .word emit
    .asciz "emit"
    .align 4
    .word 2
    .word sysexit
    .asciz "sysexit"
    .align 4
    .word 2
    .word dot
    .asciz "."
    .align 4
    .word 1
    .word over
    .asciz "over"
    .align 4
    .word 2
    .word str_eq
    .asciz "str="
    .align 4
    .word 2
    .word find
    .asciz "find"
    .align 4
    .word 2
    @ end with this:
    dp: .word . - 4

  dup:      .word code_dup
  drop:     .word code_drop
  lit:      .word code_lit
  syscall1: .word code_syscall1
  emit:     .word code_emit
  sysexit:  .word sys_exit  @ don't need a version with `b next` for this
  dot:      .word code_dot
  over:     .word code_over
  word:     .word code_word
  at:       .word code_at
  str_eq:   .word code_str_eq
  find:     .word code_find

  test_code:
    .word 0, word, find, dot, lit, 0, sysexit

.text
  dodoes:
    push {r0}
    @ `next` leaves the CFA in r7
    @ we need to push CFA+8
    @ and setup IP for docol
    @ then we maybe can fall through to docol
  docol:
    @ push ip on rs:
    str r11, [r12, #-4]!
    mov r11, r10
    @ set up new ip:
    add r10, r7, #4
    @ fall through to `next`
  next:
    ldr r7, [r10], #4  @ get CFA, keep it here for dodoes
    ldr pc, [r7]       @ get code field value

  code_dup:
    push {r0}
    b next

  code_drop:
    pop {r0}
    b next

  code_lit:
    push {r0}
    ldr r0, [r10], #4
    b next

  code_swap:
    mov r1, r0
    ldr r0, [sp]
    str r1, [sp]
    b next

  code_over:
    push {r0}
    ldr r0, [sp, #4]
    b next

  code_at:
    ldr r0, [r0]
    b next

  code_syscall1:
    mov r7, r0
    pop {r0}
    swi 0
    b next

  code_dot:
    bl puti
    mov r0, #32  @ ascii space
    @ fall through
  code_emit:
    bl putc
    pop {r0}
    b next

  code_word:
    push {r0}
    bl get_word
    b next

  code_str_eq:
    pop {r1}
    bl str_equal
    mov r0, r2
    b next

  code_find:
    bl find_word
    b next

  @ expects char in r0
  putc:
    ldr r6, =output_pos
    ldr r5, [r6]
    strb r0, [r5], #1  @ store char
    str r5, [r6]       @ store new pos

    ldr r6, =output_buffer_end
    cmp r5, r6         @ end of buffer..
    cmpne r0, #10      @ ..or newline
    bxne lr
    @ fall through
  flush:
    mov r4, r0 @ backup tos

    mov r7, #syscallid_write
    mov r0, #fd_stdout
    ldr r1, =output_buffer
    ldr r5, =output_pos
    ldr r2, [r5]
    sub r2, r2, r1  @ len
    swi 0

    @ TODO: check result

    str r1, [r5] @ reset pos to start of buffer
    mov r0, r4 @ restore tos
    bx lr

  puti:
    cmp r0, #0
    blt .Lnegative
  .Lpositive:
    push {lr}
    mov r1, #10
    bl divmod
    push {r1}
    cmp r0, #0
    blne .Lpositive
    pop {r1}
    push {r0}
    add r0, r1, #48   @ ascii '0'
    bl putc
    pop {r0, pc}

  .Lnegative:
    push {r0, lr}
    mov r0, #45      @ ascii '-' sign
    bl putc
    pop {r0, lr}
    rsb r0, r0, #0   @ r0 = -r0
    b .Lpositive

  divmod:
    @ calculates r0 divmod r1, delivers quotient in r0, modulo in r1
    @ formula: modulo = numerator - (quotient * denominator)
    sdiv r3, r0, r1
    mul r1, r3, r1
    sub r1, r0, r1
    mov r0, r3
    bx lr

  .global _start
  _start:

    ldr r12, =return_stack_bottom

    ldr r7, =test_code
    b docol

  .Lloop:
    bl getc
    cmp r0, #-1
    beq .Lend
    bl putc
    b .Lloop

  .Lend:
    mov r0, #0
    b sys_exit

  @ expects error code in r0
  sys_exit:
    bl flush
    mov r7, #syscallid_exit
    swi 0

  @ expects char in r0; don't call before getc!
  ungetc:
    ldr r5, =input_pos
    ldr r1, [r5]
    strb r0, [r1, #-1]
    bx lr

  @ returns char in r0
  getc:
    ldr r5, =input_pos
    ldr r1, [r5]
    ldr r2, =input_end
    ldr r2, [r2]

    cmp r1, r2
    beq .Lfill_buffer

  .Lreturn_char:
    ldrb r0, [r1], #1
    str r1, [r5]
    bx lr

  .Lfill_buffer:
    mov r7, #syscallid_read
    mov r0, #fd_stdin
    ldr r1, =input_buffer
    mov r2, #io_bufsize
    swi #0

    mov r2, #0
    cmp r2, r0
    beq .Leof
    bgt .Lread_error

    ldr r6, =input_pos
    str r1, [r6]

    ldr r6, =input_end
    add r2, r1, r0
    str r2, [r6]
    b .Lreturn_char

  .Leof:
    mov r0, #-1
    bx lr

  .Lread_error:
    mov r0, #1
    b sys_exit  @ FIXME: there is room for improving the error handling

  @ return pointer to next word string in r0
  get_word:
    push {lr}
  .Lskip_whitespace:
    bl getc
    cmp r0, #32    @ ascii space
    cmpne r0, #10  @ ascii newline
    beq .Lskip_whitespace
    cmp r0, #91    @ ascii [
    bleq .Linc_state
    cmp r0, #93    @ ascii ]
    bleq .Ldec_state

    push {r8}
    ldr r8, =word_scratch
  .Lstore_char:
    strb r0, [r8], #1
    bl getc
    cmp r0, #32   @ see above
    cmpne r0, #10
    cmpne r0, #91
    cmpne r0, #93
    bne .Lstore_char

    bl ungetc  @ need to keep [] for later
    mov r0, #0
  .Lzero_terminate:
    strb r0, [r8], #1
    tst r8, #3  @ lowest bits clear?
    bne .Lzero_terminate

    ldr r2, =word_scratch
    sub r3, r8, r2
    mov r3, r3, lsr #2 @ divide by 4
    str r3, [r8]       @ store len
    mov r0, r8
    pop {r8, pc}

  .Linc_state:
    ldr r7, =state
    ldr r6, [r7]
    add r6, r6, #1
    str r6, [r7]
    bx lr

  .Ldec_state:
    ldr r7, =state
    ldr r6, [r7]
    add r6, r6, #-1
    cmp r6, #0
    blt .Lstate_error
    str r6, [r7]
    bx lr

  .Lstate_error:
    mov r0, #1
    b sys_exit  @ FIXME: there is room for improving the error handling

  @ expect a string in r0, return the CFA in r0
  @ TODO: detect end of dict
  find_word:
    push {lr}
    ldr r1, =dp
    ldr r1, [r1]  @ load dp value
  .Lnext_entry:
    bl str_equal
    cmp r2, #0
    ldr r3, [r1]            @ strlen
    sub r1, r1, r3, lsl #2  @ r1=start of string
    subeq r1, r1, #8
    beq .Lnext_entry
    sub r0, r1, #4
    pop {pc}

  @ compare strings in r0 and r1; keep r0 and r1 unmodified, return result in r2
  str_equal:
    ldr r2, [r0]
    ldr r3, [r1]
    @ get start of strings:
    sub r4, r0, r2, lsl #2
    sub r5, r1, r3, lsl #2

  .Lnext_word:
    cmp r2, r3
    movne r2, #0
    bxne lr       @ return false if different

    ldr r2, [r4], #4
    ldr r3, [r5], #4
    cmp r4, r0
    bne .Lnext_word  @ continue until end of word

    mvn r2, #1    @ return true
    bx lr
