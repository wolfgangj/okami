default rel
extern runtime.outofbounds

section .text

;;;;;;;;;;;;;;;; stack ops

drop:
        mov rax, [rbp+8]
        add rbp, 8

nip:
        add rbp, 8

this:
        mov [rbp], rax
        sub rbp, 8

that:
        mov rdx, [rbp+8]
        mov [rbp], rdx
        sub rbp, 8

them:
        mov rdx, [rbp+8]
        mov [rbp], rax
        mov [rbp-8], rdx
        sub rbp, 16

alt:
        mov rdx, [rbp+8]
        mov [rbp+8], rax
        mov rax, rdx

tuck:
        mov rdx, [rbp+8]
        mov [rbp+8], rax
        mov [rbp], rdx
        sub rbp, 8

dropem:
        mov rax, [rbp+24]
        add rbp, 16

;;;;;;;;;;;;;;;; method call

method_call:
        mov [rsi], rdi
        mov rdi, rax
        mov rax, [rbp+8]
        add rbp, 8
        sub rsi, 8
        call that ; the method
        mov rdi, [rsi+8]
        add rsi, 8

;;;;;;;;;;;;;;;; math

add:
        add rax, [rbp+8]
        add rbp, 8

sub:
        mov rdx, [rbp+8]
        add rbp, 8
        sub rdx, rax
        mov rax, rdx

mul:
        imul qword [rbp+8]
        add rbp, 8

div:
        idiv qword [rbp+8]
        add rbp, 8

mod:
        idiv qword [rbp+8]
        add rbp, 8
        mov rax, rdx

;;;;;;;;;;;;;;;; logic

not:
        not rax

and:
        and rax, [rbp+8]
        add rbp, 8

or:
        or rax, [rbp+8]
        add rbp, 8

xor:
        xor rax, [rbp+8]
        add rbp, 8

;;;;;;;;;;;;;;;; shifts

ashift_right:
        sarx rax, [rbp+8], rax
        add rbp, 8

shift_right:
        shrx rax, [rbp+8], rax
        add rbp, 8

shift_left:        
        shlx rax, [rbp+8], rax
        add rbp, 8

;;;;;;;;;;;;;;;; array index

idx:
        mov rdx, [rbp+8]
        add rbp, 8
          ; oob check:
          cmp rdx, 20 ; size of array
          jae runtime.outofbounds ; unsigned, so we only have to check upper
        lea rax, [rax+rdx*8] ; size of element

;;;;;;;;;;;;;;;; control structures

if_check:
        add rbp, 8
        test rax, rax
        mov rax, [rbp+8]
        jz end_if
        ;;; code of then_branch
end_if:

eif_check:
        add rbp, 8
        test rax, rax
        mov rax, [rbp+8]
        jz else_branch
        ;;; code of then_branch
        jmp end_eif
else_branch:
        ;;; code of else-branch
end_eif:

ehas_check:
        test rax, rax
        jz ehas_else
        ;;; code of then-branch
ehas_else:
        mov rax, [rbp+8] ; drop1
        add rbp, 8       ; drop2
        ;;; code of else-branch
end_ehas:

loop:
        ;; body of loop
break:
        jmp end_of_loop
        ;; more body of loop
jmp loop
end_of_loop:

;;;;;;;;;;;;;;;; mem ops

at_64:
        mov rax, [rax]

at_s32:
        movsxd rax, [rax]

at_s16:
        movsx rax, word [rax]

at_s8:
        movsx rax, byte [rax]

at_u8:
        movzx rax, byte [rax]

at_u16:
        movzx rax, word [rax]

at_u32:
        mov eax, dword [rax] ; this will clear the upper 32 bit

store_64:
        mov rdx, [rbp+8]
        add rbp, 16
        mov [rax], rdx
        mov rax, [rbp]

store_32:
        mov edx, [rbp+8]
        add rbp, 16
        mov [rax], edx
        mov rax, [rbp]

store_16:
        mov dx, [rbp+8]
        add rbp, 16
        mov [rax], dx
        mov rax, [rbp]

store_8:
        mov dl, [rbp+8]
        add rbp, 16
        mov [rax], dl
        mov rax, [rbp]

;;;;;;;;;;;;;;;; relational ops

is_eq_alternative: ; this would also work:
        xor edx, edx
        cmp rax, [rbp+8]
        setnz dl
        mov rax, rdx
        dec rax
        add rbp, 8

is_eq_alternative2: ; this would also work, uses no rdx:
        cmp rax, [rbp+8]
        mov eax, 0 ; break register dependency (no xor to avoid flags change)
        setnz al
        dec rax
        add rbp, 8

is_eq:
        cmp rax, [rbp+8]
        setnz dl
        movzx rax, dl
        dec rax
        add rbp, 8

is_neq:
        cmp rax, [rbp+8]
        setz dl
        movzx rax, dl
        dec rax
        add rbp, 8

is_l:
        cmp rax, [rbp+8]
        setnl dl
        dec rdx
        movzx rax, dl

