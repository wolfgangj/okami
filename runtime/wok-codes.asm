default rel
extern runtime.outofbounds

; TODO: temporary hack until we can define classes
extern outofbounds

;;;;;;;;;;;;;;;; constants

%macro wok_const_int 1
        mov [rbp], rax
        sub rbp, 8
        mov rax, %1
%endmacro

%macro wok_const_0 0
        mov [rbp], rax
        sub rbp, 8
        xor eax, eax
%endmacro

%macro wok_var 1
        mov [rbp], rax
        sub rbp, 8
        lea rax, [%1]
%endmacro

;;;;;;;;;;;;;;;; stack ops

%macro wok_drop 0
        mov rax, [rbp+8]
        add rbp, 8
%endmacro

%macro wok_nip 0
        add rbp, 8
%endmacro

%macro wok_this 0
        mov [rbp], rax
        sub rbp, 8
%endmacro

%macro wok_that 0
        mov rdx, [rbp+8]
        mov [rbp], rdx
        sub rbp, 8
%endmacro

%macro wok_them 0
        mov rdx, [rbp+8]
        mov [rbp], rax
        mov [rbp-8], rdx
        sub rbp, 16
%endmacro

%macro wok_alt 0
        mov rdx, [rbp+8]
        mov [rbp+8], rax
        mov rax, rdx
%endmacro

%macro wok_tuck 0
        mov rdx, [rbp+8]
        mov [rbp+8], rax
        mov [rbp], rdx
        sub rbp, 8
%endmacro

%macro wok_dropem 0
        mov rax, [rbp+24]
        add rbp, 16
%endmacro

;;;;;;;;;;;;;;;; classes

%macro wok_method_call 1 ; method-name
        mov [rsi], rdi          ; move object from data to object stack
        mov rdi, rax
        mov rax, [rbp+8]
        add rbp, 8
        sub rsi, 8

        call %1                 ; the method

        mov rdi, [rsi+8]
        add rsi, 8
%endmacro

%macro wok_self 0
        mov [rbp], rax          ; copy from obj stack to data stack
        sub rbp, 8
        mov rax, rdi
%endmacro

%macro wok_attr_access 1 ; offset
        add rax, %1             ; offset of attribute in object
%endmacro

;;;;;;;;;;;;;;;; math

%macro wok_add 0
        add rax, [rbp+8]
        add rbp, 8
%endmacro

%macro wok_sub 0
        mov rdx, [rbp+8]
        add rbp, 8
        sub rdx, rax
        mov rax, rdx
%endmacro

%macro wok_mul 0
        imul qword [rbp+8]
        add rbp, 8
%endmacro

%macro wok_div 0
        idiv qword [rbp+8]
        add rbp, 8
%endmacro

%macro wok_mod 0
        idiv qword [rbp+8]
        add rbp, 8
        mov rax, rdx
%endmacro

;;;;;;;;;;;;;;;; logic

%macro wok_not 0
        not rax
%endmacro

%macro wok_and 0
        and rax, [rbp+8]
        add rbp, 8
%endmacro

%macro wok_or 0
        or rax, [rbp+8]
        add rbp, 8
%endmacro

%macro wok_xor 0
        xor rax, [rbp+8]
        add rbp, 8
%endmacro

;;;;;;;;;;;;;;;; shifts

%macro wok_ashift_right 0
        sarx rax, [rbp+8], rax
        add rbp, 8
%endmacro

%macro wok_shift_right 0
        shrx rax, [rbp+8], rax
        add rbp, 8
%endmacro

%macro wok_shift_left 0
        shlx rax, [rbp+8], rax
        add rbp, 8
%endmacro

;;;;;;;;;;;;;;;; array index

%macro wok_idx 2 ; array-elements element-size
        mov rdx, [rbp+8]
        add rbp, 8
          ; oob check:
          cmp rdx, %1                   ; size of array
          ; TODO: temporary hack until we can define classes
          jae outofbounds       ; unsigned, so only checking upper
          ;jae runtime.outofbounds       ; unsigned, so only checking upper
        lea rax, [rax+rdx*%2]           ; size of element
%endmacro

;;;;;;;;;;;;;;;; control structures

%macro wok_if_check 1 ; end-label
        add rbp, 8
        test rax, rax
        mov rax, [rbp+8]
        jz %1
%endmacro

%macro wok_if_end 1 ; end-label
        %1:
%endmacro

%macro wok_eif_check 1 ; else-label
        add rbp, 8
        test rax, rax
        mov rax, [rbp+8]
        jz %1
%endmacro

%macro wok_eif_else 2 ; end-label else-label
        jmp %1
        %2:
%endmacro

%macro wok_eif_end 1 ; end-label
        %1:
%endmacro

%macro wok_ehas_check 1 ; else-label
        test rax, rax
        jz %1
%endmacro

%macro wok_ehas_else 2 ; end-label else-label
        jmp %1
        %2:
        mov rax, [rbp+8] ; drop1
        add rbp, 8       ; drop2
%endmacro

%macro wok_ehas_end 1 ; end-label
       %1:
%endmacro

%macro wok_loop_start 1 ; start-label
        %1:
%endmacro

; in combination with 'new', we have to insert exit code for 'new' before this
%macro wok_break 1 ; end-label
        jmp %1
%endmacro

%macro wok_loop_end 2 ; start-label end-label
        jmp %1
        %2:
%endmacro

%macro wok_ok 0
        ret
%endmacro

;;;;;;;;;;;;;;;; mem ops

%macro wok_at_64 0
        mov rax, [rax]
%endmacro

%macro wok_at_s32 0
        movsxd rax, [rax]
%endmacro

%macro wok_at_s16 0
        movsx rax, word [rax]
%endmacro

%macro wok_at_s8 0
        movsx rax, byte [rax]
%endmacro

%macro wok_at_u8 0
        movzx rax, byte [rax]
%endmacro

%macro wok_at_u16 0
        movzx rax, word [rax]
%endmacro

%macro wok_at_u32 0
        mov eax, dword [rax] ; this will clear the upper 32 bit
%endmacro

%macro wok_store_64 0
        mov rdx, [rbp+8]
        add rbp, 16
        mov [rax], rdx
        mov rax, [rbp]
%endmacro

%macro wok_store_32 0
        mov edx, [rbp+8]
        add rbp, 16
        mov [rax], edx
        mov rax, [rbp]
%endmacro

%macro wok_store_16 0
        mov dx, [rbp+8]
        add rbp, 16
        mov [rax], dx
        mov rax, [rbp]
%endmacro

%macro wok_store_8 0
        mov dl, [rbp+8]
        add rbp, 16
        mov [rax], dl
        mov rax, [rbp]
%endmacro

;;;;;;;;;;;;;;;; relational ops

%macro wok_is_eq0 0 ; nothing to do here
%endmacro

%macro wok_is_ne0 0
        not rax
%endmacro

%macro wok_is_eq 0
        xor edx, edx
        cmp rax, [rbp+8]
        setnz dl
        mov rax, rdx
        dec rax
        add rbp, 8
%endmacro

%macro wok_is_neq 0
        xor edx, edx
        cmp rax, [rbp+8]
        setz dl
        mov rax, rdx
        dec rax
        add rbp, 8
%endmacro

%macro wok_is_l 0
        xor edx, edx
        cmp rax, [rbp+8]
        setnl dl
        mov rax, rdx
        dec rax
        add rbp, 8
%endmacro

%macro wok_is_ge 0
        xor edx, edx
        cmp rax, [rbp+8]
        setl dl
        mov rax, rdx
        dec rax
        add rbp, 8
%endmacro

%macro wok_is_g 0
        xor edx, edx
        cmp rax, [rbp+8]
        setng dl
        mov rax, rdx
        dec rax
        add rbp, 8
%endmacro

%macro wok_is_le 0
        xor edx, edx
        cmp rax, [rbp+8]
        setg dl
        mov rax, rdx
        dec rax
        add rbp, 8
%endmacro

;;;;;;;;;;;;;;;; allocation

; TODO: this can be optimized, we don't need to push rsp
%macro wok_new_start 1 ; class-name
        mov [rsi], rdi  ; make space in top of obj stack
        sub rsi, 8

        push rsp        ; so that we can restore later

        mov rdx, %1._size
        sub rsp, rdx    ; allocate
        mov rdi, rsp    ; set top of obj stack

        call %1.new

        mov [rbp], rax  ; move top of data stack to top of object stack
        mov rax, rdi
        mov rdi, [rsi+8]
        add rsi, 8
        sub rbp, 8
%endmacro

%macro wok_new_end 0
        pop rsp         ; restore original call stack
%endmacro

;;;;;;;;;;;;;;;; tagged unions

%macro wok_is 2 ; tag-value end-label
        mov rdx, [rax]
        cmp rdx, %1      ; tag value
        jne %2
        add rax, 8
%endmacro

%macro wok_is_end 1 ; end-label
        %2:
%endmacro
