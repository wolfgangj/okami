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
@ r1-r7 - scratch (caller saved), r7 also holds the CFA temporariely for docol etc.
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
.equ fd_stderr, 2
.equ ioctl_TCGETS, 0x5401

.equ io_bufsize, 4096
.equ max_wordsize, 32
.equ rs_size, 30 @ in words

.bss
  return_stack:
    .space rs_size * 4
  return_stack_bottom:
    .space 8   @ for safety; TODO: should this be `quit` maybe?

    .balign 4   @ for whatever reason, it wasn't aligned otherwise
  word_scratch:
    .space max_wordsize

  state:
    .space 4
  sp_base:
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
    @ entry format: CFA, zero-terminated string, number of cells in string
    .balign 4

    .word dup
    .asciz "dup"
    .balign 4
    .word 1

    .word drop
    .asciz "drop"
    .balign 4
    .word 2

    .word lit
    .asciz "lit"
    .balign 4
    .word 1

    .word syscall1
    .asciz "syscall1"
    .balign 4
    .word 3

    .word emit
    .asciz "emit"
    .balign 4
    .word 2

    .word sysexit
    .asciz "sysexit"
    .balign 4
    .word 2

    .word dot
    .asciz "."
    .balign 4
    .word 1

    .word over
    .asciz "over"
    .balign 4
    .word 2

    .word word
    .asciz "word"
    .balign 4
    .word 2

    .word at
    .asciz "@"
    .balign 4
    .word 1

    .word plus
    .asciz "+"
    .balign 4
    .word 1

    .word str_eq
    .asciz "str="
    .balign 4
    .word 2

    .word find
    .asciz "find"
    .balign 4
    .word 2

    .word str2int
    .asciz "str2int"
    .balign 4
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
  plus:     .word code_plus
  str_eq:   .word code_str_eq
  find:     .word code_find
  str2int:  .word code_str2int

  continue_interpreting:
    .word continue_interpreting_codefield
  continue_interpreting_codefield:
    .word next_word

  prompt:
    .ascii "\033[0m\n\033[31mok\033[mami: "
    .equ prompt_size, . - prompt
  system_response:
  welcome_message: @ starts with system message
    .ascii "\033[33;1msystem\033[0m: "
    .equ system_response_size, . - system_response
    .ascii "version 0.0"
    .equ welcome_message_size, . - welcome_message

  test_code:
    .word 0, lit, -33, word, str2int, dot, dot, lit, 0, sysexit

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
    ldr r7, [r10], #4  @ get CFA, keep it here for dodoes/docol
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

  code_plus:
    pop {r1}
    add r0, r0, r1
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

  code_str2int:
    bl string_to_int
    cmp r1, #0
    pushne {r0}
    mov r0, r1
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
    mov r0, #fd_stderr
    mov r7, #syscallid_write
    ldr r1, =prompt
    mov r2, #prompt_size
    swi #0

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

    push {r1}
    mov r0, #fd_stderr
    mov r7, #syscallid_write
    ldr r1, =system_response
    mov r2, #system_response_size
    swi #0
    pop {r1}

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
    beq .Linc_state
    cmp r0, #93    @ ascii ]
    beq .Ldec_state

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
    b .Lskip_whitespace

  .Ldec_state:
    ldr r7, =state
    ldr r6, [r7]
    add r6, r6, #-1
    cmp r6, #0
    blt .Lstate_error
    str r6, [r7]
    b .Lskip_whitespace

  .Lstate_error:
    mov r0, #1
    b sys_exit  @ FIXME: there is room for improving the error handling

  @ expect a string in r0, return the CFA in r0
  find_word:
    push {r8, lr}
    ldr r1, =dp
    ldr r1, [r1]  @ load dp value
    ldr r8, =builtin_dictionary
  .Lnext_entry:
    cmp r1, r8
    blt .Lend_of_dict
    bl str_equal
    cmp r2, #0
    ldr r3, [r1]            @ strlen
    sub r1, r1, r3, lsl #2  @ r1=start of string
    subeq r1, r1, #8
    beq .Lnext_entry
    ldr r0, [r1, #-4]  @ load CFA
    pop {r8, pc}

  .Lend_of_dict:
    mov r0, #0
    pop {r8, pc}

  @ expect a string in r0, return corresponding number in r0 and true in r1, or false in r1
  string_to_int:
    ldr r1, [r0]            @ len
    sub r1, r0, r1, lsl #2  @ r1 = parse pos in string
    mov r0, #0              @ r0 = accumulator
    mov r2, #0              @ r2 = number found? (to catch empty string, "+" and "-")
    mov r3, #0              @ r3 = is negative number?
    add r4, r1, #1          @ r4 = one past start of string
    mov r7, #10             @ base needs to be in a register for multiplication
  .Lnext_char:
    ldrb r5, [r1], #1     @ current char
    cmp r5, #48           @ ascii '0'
    blt .Lnot_a_digit
    cmp r5, #57           @ ascii '9'
    bgt .Lnot_a_digit

    mvn r2, #0            @ number found
    sub r5, r5, #48       @ ascii char to numeric value
    mla r0, r7, r0, r5
    b .Lnext_char

  .Lnot_a_digit:
    cmp r5, #0
    beq .Lend_of_number

    cmp r4, r1            @ start of string? (r1 was incremented already)
    bne .Lreturn_false    @ if not, return false

    cmp r5, #45           @ ascii '-'
    mvneq r3, #0          @ it is a negative number
    cmpne r5, #43         @ ascii '+'
    beq .Lnext_char
  .Lreturn_false:
    mov r1, #0
    bx lr

  .Lend_of_number:
    cmp r2, #0           @ number found?
    beq .Lreturn_false
    cmp r3, #0           @ negative number?
    rsbne r0, r0, #0
    mvn r1, #0
    bx lr

  @ compare strings in r0 and r1; keep r0 and r1 unmodified, return result in r2
  str_equal:
    ldr r2, [r0]
    ldr r3, [r1]
    @ get start of strings:
    sub r4, r0, r2, lsl #2
    sub r5, r1, r3, lsl #2

  .Lnext_cell:
    cmp r2, r3
    movne r2, #0
    bxne lr       @ return false if different

    ldr r2, [r4], #4
    ldr r3, [r5], #4
    cmp r4, r0
    ble .Lnext_cell  @ continue until end of word

    mvn r2, #0    @ return true
    bx lr

  interpreter:
    ldr r12, =return_stack_bottom
    ldr r1, =sp_base
    ldr sp, [r1]

  next_word:
    push {r0}
    bl flush
    bl get_word
    mov r8, r0
    bl find_word
    cmp r0, #0
    beq .Ltry_number
    ldr r1, [r0]
    mov r7, r0   @ setup CFA for docol/dodoes
    ldr r10, =continue_interpreting
    pop {r0}
    bx r1

  .Ltry_number:
    mov r0, r8
    bl string_to_int
    cmp r1, #0
    beq .Lundefined_word
    b next_word    @ number is already in r0 and previous r0 was pushed

  .Lundefined_word:
    mov r0, #2
    b sys_exit

  .global _start
  _start:
    mov r0, #fd_stderr
    mov r7, #syscallid_write
    ldr r1, =welcome_message
    mov r2, #welcome_message_size
    swi #0

    @ protect from stack underflows:
    mov r0, #0
    push {r0}
    push {r0}
    push {r0}

    ldr r1, =sp_base
    str sp, [r1]

    bl interpreter
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
