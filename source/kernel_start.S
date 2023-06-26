[bits 32]

section .text
extern kmain

global _start
_start:
    mov esp, 0x3000
    cli
    call kmain

