extern printf
extern exit

global main

section .data
  format db "hello world %c", 10, 0

  format2 db "%s",0
section .text

int_to_hex:
    push ebp    ; + 4 bytes
    mov ebp, esp

    xor eax,eax
    mov eax, [ebp+8]
    and eax, 0xf
    cmp al,9
    jg .b1
    ;mov ax, [ebp+4]
    add al, '0'
    jmp .b2
    .b1:
    ;mov ax, [ebp+4]
    sub al, 10
    add al, 'A'
    .b2:
.return:
    mov esp, ebp
    pop ebp
    ret

print_address:
    push ebp         ; caller base stack pointer        ; changed bp->ebp
    mov ebp, esp      ; base pointer = stack pointer    ; changed to 32 bit reg
    sub esp, 4        ; 4 bytes of local variables

    mov word [ebp-2], 0x12ab
    mov byte [ebp-3], 0

    .loop_start:
    cmp byte [ebp-3], 4
    jnl .loop_end

    xor eax,eax
    mov ax, word [ebp-2]
    and ax, 0xf
    
    push ax
    call int_to_hex
    add sp,2
    ; return value in eax
    
    push eax
    push format
    call printf
    add sp, 8
    
    mov ax, word[ebp-2]
    shr ax, 4
    mov word[ebp-2], ax
    mov al,byte[ebp-3]
    add al, 1
    mov byte[ebp-3], al
    jmp .loop_start
    
    .loop_end:

    .return:

    mov esp, ebp
    pop ebp
    ret


print_address2:
    push ebp
    mov ebp, esp
    sub esp, 5

    mov byte [ebp-1], 0
    mov ax, si
    and ax, 0xf
    mov byte [ebp-2], 'd'
    shr si, 4
    mov ax, si
    and ax, 0xf
    mov byte [ebp-3],'c'
    shr si, 4
    mov ax, si
    and ax, 0xf
    mov byte [ebp-4], 'b'
    shr si, 4
    mov ax, si
    and ax, 0xf
    mov byte [ebp-5],'a'

    mov esi, ebp
    sub esi, 5
    push esi
    push format2
    call printf
    
    mov esp, ebp
    pop ebp
    ret 

main:
    mov ebp, esp

    mov eax, 6
    add eax, 2

    ;xor eax,eax
    ;push word 0x4b1a
    ;call int_to_hex ; + 4 bytes
    ;add sp, 2

    ;mov eax, 'A'

    ;push  eax
    ;push  format
    ;call  printf  ; printf(format, eax)

    call print_address2

    push  0
    call exit     ; exit(0)

