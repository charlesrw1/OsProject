section .text
bits 32

; push dummy error code (0)
; push frame
; push interrupt number

%macro ISR_NO_ERR 1
section .text
intr%1_stub:
    push DWORD 0
    push ebp
    push DWORD %1
    jmp intr_entry

section .data
    dd intr%1_stub
%endmacro

; error code on stack already
; push frame
; push interrupt number

%macro ISR_ERR 1
section .text
intr%1_stub:
    push ebp
    push DWORD %1
    jmp intr_entry

section .data
    dd intr%1_stub
%endmacro

; array of ISRs in interrupt.c
section .data
global intr_stubs
intr_stubs:

ISR_NO_ERR 0
ISR_NO_ERR 1
ISR_NO_ERR 2
ISR_NO_ERR 3
ISR_NO_ERR 4
ISR_NO_ERR 5
ISR_NO_ERR 6
ISR_NO_ERR 7
ISR_ERR 8
ISR_NO_ERR 9
ISR_ERR 10
ISR_ERR 11
ISR_ERR 12
ISR_ERR 13
ISR_ERR 14
ISR_NO_ERR 15
ISR_NO_ERR 16
ISR_NO_ERR 17
ISR_NO_ERR 18
ISR_NO_ERR 19
ISR_NO_ERR 20
ISR_NO_ERR 21
ISR_NO_ERR 22
ISR_NO_ERR 23
ISR_NO_ERR 24
ISR_NO_ERR 25
ISR_NO_ERR 26
ISR_NO_ERR 27
ISR_NO_ERR 28
ISR_NO_ERR 29
ISR_NO_ERR 30
ISR_NO_ERR 31
ISR_NO_ERR 32
ISR_NO_ERR 33
ISR_NO_ERR 34
ISR_NO_ERR 35
ISR_NO_ERR 36
ISR_NO_ERR 37
ISR_NO_ERR 38
ISR_NO_ERR 39
ISR_NO_ERR 40
ISR_NO_ERR 41
ISR_NO_ERR 42
ISR_NO_ERR 43
ISR_NO_ERR 44
ISR_NO_ERR 45
ISR_NO_ERR 46
ISR_NO_ERR 47

extern interrupt_handler_common

section .text
intr_entry:
; FUGGGG
    o16 push ds
    o16 push es
    o16 push fs
    o16 push gs
    pusha

    mov eax, 0x10   ; kernel code segment
    mov ds, eax
    mov es, eax
    mov fs, eax
    mov gs, eax

    cld
    push esp
; defined in interrupt.c
    call interrupt_handler_common
    add esp, 4

    popa
    o16 pop gs
    o16 pop fs
    o16 pop es
    o16 pop ds
; intr_frame, vec_number, error
    add esp, 12
    iret
