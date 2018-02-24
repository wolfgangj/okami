@ okami.s - the beginnings of a project
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

.equ syscallid_exit, 1
.equ syscallid_read, 3
.equ syscallid_write, 4
.equ fd_stdin, 0
.equ fd_stdout, 1
.equ ioctl_TCGETS, 0x5401

.equ io_bufsize, 4096

.bss
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

.text
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

  .global _start
  _start:

  .Lloop:
    bl getc
    cmp r0, #-1
    beq .Lend
    bl putc
    b .Lloop

  .Lend:
    bl flush
    mov r0, #0
    b sys_exit


  @ expects error code in r0
  sys_exit:
    mov r7, #syscallid_exit
    swi 0


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
    b sys_exit
