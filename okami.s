@ okami.s - a metamodern programming language / a non-standard dialect of Forth
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
@ r1-r5,r7 - scratch (caller saved), r7 also holds the CFA temporariely for docol etc.
@ r6    - tas
@ r8-r9 - callee saved
@ r10   - ip
@ r11   - asp, full+downward
@ r12   - rsp, full+downward
@ r13   - sp, full+downward
@ r14   - ARM lr
@ r15   - ARM ip

.equ syscallid_exit, 1
.equ syscallid_read, 3
.equ syscallid_write, 4
.equ syscallid_open, 5
.equ syscallid_close, 6
.equ syscallarg_O_RDONLY, 0
.equ fd_stdin, 0
.equ fd_stdout, 1
.equ fd_stderr, 2
.equ ioctl_TCGETS, 0x5401

.equ io_bufsize, 4096
.equ max_wordsize, 32
.equ rs_words, 62
.equ aux_words, 30

.bss
  data_space:
    .space 1024 * 500
  user_dict_end: @ dict grows downward from here

  return_stack:
    .space rs_words * 4
  return_stack_bottom:
    .space 8   @ for safety

  aux_stack:
    .space aux_words * 4
  aux_stack_bottom:
    .space 8   @ for safety

    .balign 4   @ for whatever reason, it wasn't aligned otherwise
  word_scratch:
    .space max_wordsize

  state:
    .space 1
  had_error:
    .space 1

    .balign 4
  sp_base:
    .space 4
  interpreter_register_backup:
    .space 4 * 3
  interpreter_register_backup_end:

  input_fd:
    .space 4
  input_buffer:
    .space io_bufsize
  input_pos:
    .space 4
  input_end:
    .space 4
  input_files:
    .space 4

  output_buffer:
    .space io_bufsize
  output_buffer_end:
    @ here goes nothing
.data
  output_pos:
    .word output_buffer

  here_ptr:
    .word data_space
  user_dict_ptr:
    .word user_dict_end

  .balign 4
  builtin_dict:
    .macro entry name, cfa
      .balign 4
      .word (align_\cfa - (. + 4)) / 4
      .asciz "\name"
      .balign 4
      align_\cfa:
      .word \cfa, \cfa + 4
    .endm

    entry "dup", dup
    entry "drop", drop
    entry "swap", swap
    entry "lit", lit
    entry "emit", emit
    entry "over", over
    entry "word", word
    entry "@", fetch
    entry "c@", c_fetch
    entry "!", store
    entry ",", comma
    entry "c!", c_store
    entry "+", plus
    entry "-", minus
    entry "*", multiply
    entry "/", divide
    entry "/mod", divide_mod
    entry "=?", is_eq_p
    entry "<>?", is_ne_p
    entry ">?", is_gt_p
    entry "<?", is_lt_p
    entry ">=?", is_ge_p
    entry "<=?", is_le_p
    entry "=", is_eq
    entry "<>", is_ne
    entry "<", is_lt
    entry ">", is_gt
    entry "<=", is_le
    entry ">=", is_ge
    entry ">r", to_r
    entry "r>", r_from
    entry "not", not
    entry "and", and
    entry "or", or
    entry "xor", xor
    entry "2dup", two_dup
    entry "str=", str_eq
    entry "find", find
    entry "cs>n" cs2n
    entry "nip", nip
    entry "tuck", tuck
    entry "hp", hp
    entry "c,", c_comma
    entry "exit", exit
    entry ">aux", to_aux
    entry "aux>", aux_from
    entry "aux", aux
    entry "auxdrop", auxdrop
    entry "str.", str_dot
    entry ".s", dot_s
    entry "<<", shift_left
    entry ">>", shift_right
    entry "execute", execute
    entry "rdrop", rdrop
    entry "r@", r_fetch
    entry "syscall0", syscall0
    entry "syscall1", syscall1
    entry "syscall2", syscall2
    entry "syscall3", syscall3
    entry "syscall4", syscall4
    entry "syscall5", syscall5
    entry "sysexit", sysexit
    entry "n.", n_dot
    entry "key", key
    entry "copy-str", copy_str
    entry "entry:", entry
    entry "docol,", docol_comma
    entry "dodoes,", dodoes_comma
    entry "dopush,", dopush_comma
    entry "branch", branch
    entry "0branch", zero_branch
    entry "quit", quit
    entry "dp", dp
    entry "pushkey", pushkey
    entry "depth", depth
    entry "rsbounds", rsbounds
    @ entry "(quit)", continue_interpreting  @ this requires unified dict to work in backtraces
    builtin_dict_end:

  dup:            .word code_dup
  drop:           .word code_drop
  swap:           .word code_swap
  lit:            .word code_lit
  branch:         .word code_branch
  zero_branch:    .word code_0branch
  fetch:          .word code_fetch
  store:          .word code_store
  plus:           .word code_plus

  is_eq_p:  .word code_is_eq_p
  is_ne_p:  .word code_is_ne_p
  is_lt_p:  .word code_is_lt_p
  is_gt_p:  .word code_is_gt_p
  is_le_p:  .word code_is_le_p
  is_ge_p:  .word code_is_ge_p
  is_eq:    .word code_is_eq
  is_ne:    .word code_is_ne
  is_lt:    .word code_is_lt
  is_gt:    .word code_is_gt
  is_le:    .word code_is_le
  is_ge:    .word code_is_ge
  c_fetch:  .word code_c_fetch
  c_store:  .word code_c_store
  over:     .word code_over
  nip:      .word code_nip
  tuck:     .word code_tuck
  to_aux:   .word code_to_aux
  aux_from: .word code_aux_from
  aux:      .word code_aux
  auxdrop:  .word code_auxdrop
  to_r:     .word code_to_r
  r_from:   .word code_r_from
  and:      .word code_and
  or:       .word code_or

  syscall0: .word code_syscall0
  syscall1: .word code_syscall1
  syscall2: .word code_syscall2
  syscall3: .word code_syscall3
  syscall4: .word code_syscall4
  syscall5: .word code_syscall5
  emit:     .word code_emit
  sysexit:  .word sys_exit  @ don't need a version with `next` for this
  n_dot:    .word code_n_dot
  word:     .word code_word
  minus:    .word code_minus
  multiply: .word code_multiply
  divide:   .word code_divide
  not:      .word code_not
  xor:      .word code_xor
  two_dup:  .word code_2dup
  str_eq:   .word code_str_eq
  find:     .word code_find
  cs2n:     .word code_cs2n
  hp:       .word code_hp
  comma:    .word code_comma
  c_comma:  .word code_c_comma
  exit:     .word code_exit
  dot_s:    .word code_dot_s
  str_dot:  .word code_str_dot
  rdrop:    .word code_rdrop
  r_fetch:  .word code_r_fetch
  execute:  .word code_execute
  divide_mod:   .word code_divide_mod
  shift_left:   .word code_shift_left
  shift_right:  .word code_shift_right
  docol_comma:  .word code_docol_comma
  dodoes_comma: .word code_dodoes_comma
  dopush_comma: .word code_dopush_comma
  copy_str: .word code_copy_str
  entry:    .word code_entry
  key:      .word code_key
  quit:     .word code_quit
  dp:       .word code_dp
  depth:    .word code_depth
  rsbounds: .word code_rsbounds
  pushkey:  .word code_pushkey

  continue_interpreting:
    .word continue_interpreting_codefield
  continue_interpreting_codefield:
    .word next_word

  ok_msg:
    .ascii "\033[32mok"
    .equ ok_msg_size, . - ok_msg
  err_msg:
    .ascii " \033[31merr\033[0m "
    .equ err_msg_size, . - err_msg
  prompt:
    .ascii "\033[0m\n\033[31mok\033[0;1mami\033[0m: "
    .equ prompt_size, . - prompt
  system_response:
  welcome_message: @ starts with system message
    .ascii "\033[33;1msystem\033[0m: "
    .equ system_response_size, . - system_response
    .ascii "version 0.1 welcome "
    .equ welcome_message_size, . - welcome_message
  goodbye_message:
    .ascii "bye\n"
    .equ goodbye_message_size, . - goodbye_message
  underflow_warning:
    .ascii "\033[35mstack underflow\033[0m "
    .equ underflow_warning_size, . - underflow_warning
  unbalanced_bracket_err:
    .ascii "unbalanced `]`"
    .equ unbalanced_bracket_err_size, . - unbalanced_bracket_err
  couldnt_load_file_err:
    .ascii "could not load file\n"
    .equ couldnt_load_file_err_size, . - couldnt_load_file_err

.text
  .macro load_addr reg, addr
    movw \reg, #:lower16:\addr
    movt \reg, #:upper16:\addr
  .endm

  .macro next
    ldr r7, [r10], #4  @ get CFA, keep it here for dodoes/docol
    ldr pc, [r7]       @ get code field value
  .endm

  dodoes:
    @ `next` leaves the CFA in r7, so we push CFA+8
    push {r0}
    add r0, r7, #8
    ldr r7, [r7, #4]
    sub r7, r7, #4   @ fix for docol
    @ fall through
  docol:
    @ push ip on rs:
    str r10, [r12, #-4]!
    @ set up new ip:
    add r10, r7, #4
  next: @ nice to have as a branch target
    next

  dopush:
    push {r0}
    add r0, r7, #4
    next

  code_exit:
    ldr r10, [r12], #4
    next

  code_dup:
    push {r0}
    next

  code_drop:
    pop {r0}
    next

  code_lit:
    push {r0}
    ldr r0, [r10], #4
    next

  code_swap:
    mov r1, r0
    ldr r0, [sp]
    str r1, [sp]
    next

  code_0branch:
    cmp r0, #0
    pop {r0}
    addne r10, r10, #4  @ skip address
    bne next
    @ fall through
  code_branch:
    ldr r10, [r10]
    next

  code_over:
    push {r0}
    ldr r0, [sp, #4]
    next

  code_fetch:
    ldr r0, [r0]
    next

  code_c_fetch:
    ldrb r0, [r0]
    next

  code_store:
    pop {r1, r2}
    str r1, [r0]
    mov r0, r2
    next

  code_c_store:
    pop {r1, r2}
    strb r1, [r0]
    mov r0, r2
    next

  code_plus:
    pop {r1}
    add r0, r1, r0
    next

  code_minus:
    pop {r1}
    sub r0, r1, r0
    next

  code_multiply:
    pop {r1}
    mul r0, r1, r0
    next

  code_divide:
    pop {r1}
    sdiv r0, r1, r0
    next

  code_divide_mod:
    mov r1, r0
    pop {r0}
    bl divmod
    push {r1}
    next

  code_is_eq_p:
    ldr r1, [sp]
    cmp r1, r0
    movne r0, #0
    moveq r0, #-1
    next
    
  code_is_ne_p:
    ldr r1, [sp]
    cmp r1, r0
    moveq r0, #0
    movne r0, #-1
    next

  code_is_lt_p:
    ldr r1, [sp]
    cmp r1, r0
    movge r0, #0
    movlt r0, #-1
    next

  code_is_gt_p:
    ldr r1, [sp]
    cmp r1, r0
    movle r0, #0
    movgt r0, #-1
    next

  code_is_le_p:
    ldr r1, [sp]
    cmp r1, r0
    movgt r0, #0
    movle r0, #-1
    next

  code_is_ge_p:
    ldr r1, [sp]
    cmp r1, r0
    movlt r0, #0
    movge r0, #-1
    next

  code_is_eq:
    pop {r1}
    cmp r0, r1
    movne r0, #0
    moveq r0, #-1
    next

  code_is_ne:
    pop {r1}
    cmp r0, r1
    moveq r0, #0
    movne r0, #-1
    next

  code_is_lt:
    pop {r1}
    cmp r1, r0
    movge r0, #0
    movlt r0, #-1
    next

  code_is_gt:
    pop {r1}
    cmp r1, r0
    movle r0, #0
    movgt r0, #-1
    next

  code_is_le:
    pop {r1}
    cmp r1, r0
    movgt r0, #0
    movle r0, #-1
    next

  code_is_ge:
    pop {r1}
    cmp r1, r0
    movlt r0, #0
    movge r0, #-1
    next

  code_to_r:
    str r0, [r12, #-4]!
    b code_drop

  code_r_from:
    push {r0}
    ldr r0, [r12], #4
    next

  code_rdrop:
    add r12, r12, #4
    next

  code_r_fetch:
    push {r0}
    ldr r0, [r12]
    next

  code_aux:
    push {r0}
    mov r0, r6
    next

  code_to_aux:
    str r6, [r11, #-4]!
    mov r6, r0
    pop {r0}
    next

  code_aux_from:
    push {r0}
    mov r0, r6
    ldr r6, [r11], #4
    next

  code_auxdrop:
    ldr r6, [r11], #4
    next

  code_not:
    mvn r0, r0
    next

  code_and:
   pop {r1}
   and r0, r0, r1
   next

  code_or:
   pop {r1}
   orr r0, r0, r1
   next

  code_xor:
   pop {r1}
   eor r0, r0, r1
   next

  code_2dup:
    ldr r1, [sp]
    mov r2, r0
    push {r1, r2}
    next

  code_shift_left:
    pop {r1}
    mov r0, r1, lsl r0
    next

  code_shift_right:
    pop {r1}
    mov r0, r1, lsr r0
    next

  code_execute:
    mov r7, r0
    pop {r0}
    ldr pc, [r7]

  code_nip:
    add sp, sp, #4
    next

  code_tuck:
    ldr r1, [sp]
    str r0, [sp]
    push {r1}
    next

  code_syscall0:
    mov r7, r0
    swi #0
    next

  code_syscall1:
    mov r7, r0
    pop {r0}
    swi #0
    next

  code_syscall2:
    mov r7, r0
    pop {r0, r1}
    swi #0
    next

  code_syscall3:
    mov r7, r0
    pop {r0, r1, r2}
    swi #0
    next

  code_syscall4:
    mov r7, r0
    pop {r0, r1, r2, r3}
    swi #0
    next

  code_syscall5:
    mov r7, r0
    pop {r0, r1, r2, r3, r4}
    swi #0
    next

  code_n_dot:
    bl puti
    b code_drop

  code_emit:
    bl putc
    b code_drop

  code_key:
    push {r0}
    bl getc
    next

  code_word:
    push {r0}
    bl get_word
    next

  code_str_eq:
    pop {r1}
    bl str_equal
    mov r0, r2
    next

  code_find:
    bl find_word
    cmp r0, #0
    pushne {r0}
    movne r0, #-1
    next

  code_cs2n:
    add r0, r0, #-4  @ len field is ignord by `string_to_int` anyway.
    bl string_to_int
    cmp r1, #0
    pushne {r0}
    mov r0, r1
    next

  code_hp:
    push {r0}
    load_addr r0, here_ptr
    next

  code_comma:
    load_addr r1, here_ptr
    ldr r2, [r1]
    str r0, [r2], #4
    str r2, [r1]
    b code_drop

  code_c_comma:
    load_addr r1, here_ptr
    ldr r2, [r1]
    strb r0, [r2], #1
    str r2, [r1]
    b code_drop

  code_dot_s:
    load_addr r8, sp_base
    ldr r8, [r8]
    push {r0}
    add r8, r8, #-4
    mov r9, sp
  .Lnext_item:
    cmp r8, r9
    ble code_drop
    ldr r0, [r8, #-4]!
    bl puti
    mov r0, #32
    bl putc
    b .Lnext_item

  code_str_dot:
    bl puts
    b code_drop

  code_copy_str:  @ src dst -- dst
    pop {r1}
    ldr r2, [r1]
    add r2, r2, #1
    mov r8, r0
    bl string_copy
    mov r0, r8
    next

  code_entry:
    push {r0}
    bl get_word
    mov r1, r0
    bl make_entry
    b code_drop

  code_docol_comma:
    push {r0}
    load_addr r0, docol
    b code_comma

  code_dodoes_comma:
    push {r0}
    load_addr r0, dodoes
    b code_comma

  code_dopush_comma:
    push {r0}
    load_addr r0, dopush
    b code_comma

  code_quit:
    @ keep our caller:
    str r10, [r12, #-4]!
    @ empty input buffer and set to stdin:
    load_addr r1, input_fd
    load_addr r2, input_pos
    load_addr r3, input_end
    mov r4, #fd_stdin
    str r4, [r1]
    mov r4, #0
    str r4, [r2]
    str r4, [r3]
    @ start reading interactively:
    b next_word

  code_dp:
    push {r0}
    load_addr r0, user_dict_ptr
    next

  code_pushkey:
    bl ungetc
    b code_drop

  code_depth:
    load_addr r1, sp_base
    ldr r1, [r1]
    sub r1, r1, sp
    push {r0}
    mov r0, r1, asr #2
    next

  code_rsbounds:
    push {r0}
    load_addr r1, return_stack_bottom
    push {r1}
    mov r0, r12
    next

  @ expects char in r0
  putc:
    load_addr r4, output_pos
    ldr r5, [r4]
    strb r0, [r5], #1  @ store char
    str r5, [r4]       @ store new pos

    load_addr r4, output_buffer_end
    cmp r5, r4         @ end of buffer..
    cmpne r0, #10      @ ..or newline
    bxne lr
    @ fall through
  flush:
    mov r4, r0 @ backup tos

    mov r7, #syscallid_write
    mov r0, #fd_stdout
    load_addr r1, output_buffer
    load_addr r5, output_pos
    ldr r2, [r5]
    sub r2, r2, r1  @ len
    swi #0

    @ TODO: check result

    str r1, [r5] @ reset pos to start of buffer
    mov r0, r4 @ restore tos
    bx lr

  puti:  @ does not leave r0 intact!
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

  puts:
    push {lr}
    add r8, r0, #4
  .Lput_next:
    ldrb r0, [r8], #1
    cmp r0, #0
    popeq {pc}
    bl putc
    b .Lput_next

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
    mov r8, r0
    load_addr r0, input_fd
    ldr r0, [r0]
    cmp r0, #fd_stdin
    bne .Lskip_goodbye
    load_addr r1, goodbye_message
    mov r2, #goodbye_message_size
    bl write_to_stderr
  .Lskip_goodbye:
    mov r0, r8

    mov r7, #syscallid_exit
    swi #0

  @ expects char in r0; don't call before getc!
  ungetc:
    load_addr r5, input_pos
    ldr r1, [r5]
    strb r0, [r1, #-1]!
    str r1, [r5]
    bx lr

  @ returns char in r0
  getc:
    load_addr r5, input_pos
    ldr r1, [r5]
    load_addr r2, input_end
    ldr r2, [r2]

    cmp r1, r2
    beq .Lfill_buffer

  .Lreturn_char:
    ldrb r0, [r1], #1
    str r1, [r5]
    bx lr

  .Lfill_buffer:
    @ BEGIN >>> for interactive use >>>
    load_addr r0, input_fd
    ldr r0, [r0]
    cmp r0, #fd_stdin
    bne .Lskip_prompt

    push {lr}
    bl flush

    @ check for stack underflow:
    load_addr r1, sp_base
    ldr r1, [r1]
    sub r1, r1, #(3 * 4)
    cmp r1, sp
    load_addr r1, underflow_warning
    mov r2, #underflow_warning_size
    bllt write_to_stderr

    load_addr r3, had_error
    ldrb r1, [r3]
    cmp r1, #0
    bne .Lskip_ok_msg

    load_addr r1, ok_msg
    mov r2, #ok_msg_size
    bl write_to_stderr

  .Lskip_ok_msg:
    mov r2, #0
    strb r2, [r3]   @ if we had an error, it is now cleared

    load_addr r1, prompt
    mov r2, #prompt_size
    bl write_to_stderr
    pop {lr}
  .Lskip_prompt:
    @ END <<< for interactive use <<<

    load_addr r0, input_fd
    ldr r0, [r0]
    mov r7, #syscallid_read
    load_addr r1, input_buffer
    mov r2, #io_bufsize
    swi #0

    cmp r0, #0
    beq .Leof
    blt .Lread_error

    load_addr r5, input_pos
    str r1, [r5]

    load_addr r5, input_end
    add r2, r1, r0
    str r2, [r5]

    @ BEGIN >>> for interactive use >>>
    load_addr r0, input_fd
    ldr r0, [r0]
    cmp r0, #fd_stdin
    bne .Lskip_system_response
    push {lr}
    load_addr r1, system_response
    mov r2, #system_response_size
    bl write_to_stderr
    pop {lr}
  .Lskip_system_response:
    @ END <<< for interactive use <<<

    load_addr r5, input_pos  @ restore registers
    ldr r1, [r5]
    b .Lreturn_char

  .Leof:
    mov r0, #-1
    bx lr

  .Lread_error:
    load_addr r1, couldnt_load_file_err
    mov r2, #couldnt_load_file_err_size
    bl write_to_stderr
    @ TODO: tell user which file...

    mov r0, #1
    b sys_exit

  @ return pointer to next word string in r0 (or zero on eof)
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
    cmp r0, #92    @ ascii \
    beq .Lskip_comment
    cmp r0, #-1    @ eof
    beq .Leof_before_word

    push {r8}
    load_addr r8, (word_scratch + 4)
  .Lstore_char:
    strb r0, [r8], #1
    bl getc
    cmp r0, #-1    @ eof
    beq .Lzero_terminate
    cmp r0, #32    @ see above
    cmpne r0, #10
    cmpne r0, #91
    cmpne r0, #93
    bne .Lstore_char

    bl ungetc      @ need to keep [] for later
  .Lzero_terminate:
    mov r0, #0
  .Lzero_terminate_next:
    strb r0, [r8], #1
    tst r8, #3     @ lowest bits clear?
    bne .Lzero_terminate_next

    load_addr r0, word_scratch
    add r1, r0, #4     @ beginning of string data
    sub r3, r8, r1
    mov r3, r3, lsr #2 @ divide by 4
    str r3, [r0]       @ store len
    pop {r8, pc}

  .Linc_state:
    load_addr r7, state
    ldrb r3, [r7]
    add r3, r3, #1
    strb r3, [r7]

    @ align here_ptr
    load_addr r1, here_ptr
    ldr r2, [r1]
    and r3, r2, #-4
    cmp r2, r3
    addne r2, r3, #4
    str r2, [r1]

    b .Lskip_whitespace

  .Ldec_state:
    load_addr r7, state
    ldrb r3, [r7]
    add r3, r3, #-1
    cmp r3, #0
    blt .Lstate_error
    strb r3, [r7]
    b .Lskip_whitespace

  .Leof_before_word:
    mov r0, #0
    pop {pc}

  .Lskip_comment:
    bl getc
    cmp r0, #10    @ newline
    cmpne r0, #-1  @ eof
    bne .Lskip_comment
    b .Lskip_whitespace

  .Lstate_error:
    push {r0,r1,r2,r7}

    load_addr r1, unbalanced_bracket_err
    mov r2, #unbalanced_bracket_err_size
    bl write_to_stderr
    bl error
    pop {r0,r1,r2,r7}
    b .Lskip_whitespace

  @ expect a string in r0, return the CFA in r0
  find_word:
    push {r8, r9, lr}
    mov r9, r0
    load_addr r1, user_dict_ptr
    ldr r1, [r1]
    load_addr r8, user_dict_end
    bl find_word_in_dict
    cmp r0, #0
    popne {r8, r9, pc}
    load_addr r1, builtin_dict
    load_addr r8, builtin_dict_end
    mov r0, r9
    bl find_word_in_dict
    pop {r8, r9, pc}

  @ expect a string in r0, dict start in r1, dict end in r8; return the CFA in r0
  find_word_in_dict:
    push {lr}
  .Lnext_entry:
    cmp r1, r8
    beq .Lend_of_dict
    ldr r2, [r1]
    cmp r2, #0         @ private section?
    ldreq r1, [r1, #4] @ then skip
    beq .Lnext_entry
    bl str_equal    @ leaves next address in r7
    cmp r2, #0
    bne .Lfound
    add r1, r7, #8  @ skip CFA and end-addr
    b .Lnext_entry

  .Lend_of_dict:
    mov r0, #0
    pop {pc}

  .Lfound:
    ldr r0, [r7]
    pop {pc}

  @ expect name in r1
  make_entry:
    load_addr r4, user_dict_ptr
    ldr r0, [r4]

    load_addr r3, here_ptr
    ldr r3, [r3]             @ here
    @ align it, since the CF will also be aligned
    and r2, r3, #-4
    cmp r3, r2
    addne r3, r2, #4

    ldr r2, [r1]             @ len of string
    add r2, r2, #1           @ extra space for len field
    str r3, [r0, #-4]!       @ CFA
    str r3, [r0, #-4]!       @ end of entry, may be overwritten later
    sub r0, r0, r2, lsl #2   @ make space for string
    str r0, [r4]             @ new beginning of dict
    @ fall through
  string_copy:  @ expect dest in r0, src in r1, len (in cells) including len field already in r3
    ldr r3, [r1], #4
    str r3, [r0], #4
    subs r2, r2, #1
    bne string_copy
    bx lr

  @ expect a string in r0, return corresponding number in r0 and true in r1, or false in r1
  string_to_int:
    add r1, r0, #4          @ r1 = parse pos in string
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

    cmp r4, r1            @ start of string?
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

  @ compare strings in r0 and r1; keep r0 and r1 unmodified, return result in r2.
  @ also leaves next address after r1-string in r7 if false (useful for dict search).
  str_equal:
    mov r4, r0              @ traversal pointer 1
    mov r5, r1              @ traversal pointer 1
    ldr r2, [r4], #4        @ len 1
    ldr r3, [r5], #4        @ len 2
    add r7, r1, r3, lsl #2
    add r7, r7, #4          @ next address after string

  .Lnext_cell:
    cmp r2, r3
    movne r2, #0
    bxne lr         @ return false if different
    cmp r5, r7
    mvneq r2, #0    @ return true at end of strings
    bxeq lr
    ldr r2, [r4], #4
    ldr r3, [r5], #4
    b .Lnext_cell

  interpreter:
    load_addr r12, return_stack_bottom
    load_addr r11, aux_stack_bottom
    load_addr r1, sp_base
    ldr sp, [r1]
    mov r0, #0

    @ the code_* words don't save r8, r9 and lr, so we back them up
    load_addr r1, interpreter_register_backup
    stmea r1, {r8, r9, lr}

  next_word:
    push {r0}
  .Lnext:
    bl get_word
    cmp r0, #0
    beq .Linterpreter_eof
    mov r8, r0
    bl find_word
    cmp r0, #0
    beq .Ltry_number

    load_addr r2, state
    ldrb r2, [r2]
    cmp r2, #1
    beq .Lcompile_call
    bgt .Lpostpone_call

    ldr r1, [r0]
    mov r7, r0   @ setup CFA for docol/dodoes
    load_addr r10, continue_interpreting
    pop {r0}
    bx r1

  .Lcompile_call:
    load_addr r3, here_ptr
    ldr r4, [r3]
    str r0, [r4], #4
    str r4, [r3]
    b .Lnext

  .Lpostpone_call:
    load_addr r3, here_ptr
    ldr r4, [r3]
    load_addr r5, lit
    load_addr r7, comma
    str r5, [r4], #4  @ lit
    str r0, [r4], #4  @ the value
    str r7, [r4], #4  @ comma
    str r4, [r3]
    b .Lnext

  .Ltry_number:
    mov r0, r8
    bl string_to_int
    cmp r1, #0
    beq .Lundefined_word

    load_addr r2, state
    ldrb r2, [r2]
    cmp r2, #1
    beq .Lcompile_lit
    bgt .Lpostpone_lit
    b next_word    @ old tos was already pushed and new tos is in r0

  .Lcompile_lit:
    load_addr r3, here_ptr
    ldr r4, [r3]
    load_addr r5, lit
    str r5, [r4], #4
    str r0, [r4], #4
    str r4, [r3]
    b .Lnext

  .Lpostpone_lit:
    load_addr r3, here_ptr
    ldr r4, [r3]
    load_addr r5, lit
    load_addr r7, comma
    str r5, [r4], #4  @ lit
    str r5, [r4], #4  @ lit
    str r7, [r4], #4  @ comma
    str r5, [r4], #4  @ lit
    str r0, [r4], #4  @ the value
    str r7, [r4], #4  @ comma
    str r4, [r3]
    b .Lnext

  .Linterpreter_eof:
    load_addr r1, interpreter_register_backup_end
    ldmea r1, {r8, r9, pc}

  .Lundefined_word:
    @ display error message:
    mov r0, r8
    bl puts       @ FIXME: write error message to stderr, not stdout! (puts, putc, flush)
    mov r0, #63   @ ascii '?'
    bl putc
    bl flush
    bl error

    b .Lnext

  abort:
    mov r0, #1
    b sys_exit

  error:
    push {lr}

    @ remember we just had an error:
    load_addr r1, had_error
    mov r2, #-1
    strb r2, [r1]

    @ return to interpret mode
    load_addr r1, state
    mov r2, #0
    strb r2, [r1]

    load_addr r1, err_msg
    mov r2, #err_msg_size
    bl write_to_stderr

    @ abort unless repl
    load_addr r1, input_fd
    ldr r1, [r1]
    cmp r1, #fd_stdin
    bne abort

    @ drop rest of input buffer (i.e. rest of interactive line):
    load_addr r1, input_pos
    load_addr r2, input_end
    mov r3, #0
    str r3, [r1]
    str r3, [r2]

    pop {pc}

  @ expects string in r1 and len in r2
  write_to_stderr:
    mov r0, #fd_stderr
    mov r7, #syscallid_write
    swi #0
    bx lr

  .global _start
  _start:
    @ for processing files given on command line:
    load_addr r0, input_files
    add r1, sp, #8
    str r1, [r0]

    @ protect from stack underflows:
    push {r2,r3,r4}

    load_addr r1, sp_base
    str sp, [r1]

  .Lnext_file:
    @ which file is next -> r0
    load_addr r2, input_files
    ldr r1, [r2]
    ldr r0, [r1], #4
    str r1, [r2]

    cmp r0, #0
    beq .Lread_stdin

    mov r7, #syscallid_open
    mov r1, #syscallarg_O_RDONLY
    swi #0
    @ FIXME: error handling
    load_addr r1, input_fd
    str r0, [r1]
    bl interpreter
    b .Lnext_file

  .Lread_stdin:
    load_addr r1, welcome_message
    mov r2, #welcome_message_size
    bl write_to_stderr

    load_addr r1, input_fd
    mov r0, #fd_stdin
    str r0, [r1]
    bl interpreter

    mov r0, #0
    b sys_exit
