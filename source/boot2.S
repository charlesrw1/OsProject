bits 16

; jumped to from boot1.S at 0x7c00
; in real mode
; read memory information
; switch to protected mode
; go to c code to search filesystem/load the kernel from the disk
;   jumps to kernel which will be loaded at 1MB

extern kmain

section .text.prologue
global _start
_start:
    jmp 0:go
go:
;   initialize segments
    xor ax,ax
    mov ds, ax
    mov ss, ax
    mov sp, 0x7c00
    mov [drive_num], dl   ; save drive number from bios
    
    sti

    mov si, startup_str
    call print

    ; enable a20 gate
    ; todo, add enable routine
    in al, 0x92
    or al, 2
    out 0x92, al
    call check_a20
    cmp ax, 1
    jne a20_not_enabled


    ; get drive information
    ; get memory information


    ; switch to protected mode
    cli
    lgdt [gdt_r]
    mov eax, cr0
    or eax, 1
    mov cr0,eax         ; set protection ebaled
    mov ax,0x10  ; data entry is offset 16 bytes in GDT
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov gs,ax
    mov ss,ax
    ; long jump
    jmp 0x8:kmain

    hlt

; Prints null terminated string in SI to screen
print:
    mov bh, 0       ; page number
    mov ah, 0x0e    ; print character
    mov al, [si]
    add si, 1
    cmp al, 0
    je .return
    int 0x10        ; issue interrupt
    jmp print
.return:
    ret


; check if a20 is enabled
; returns 0 in ax if disabled, 1 if enabled
check_a20:
    pushf
    push ds
    push es
    push di
    push si
 
    cli
 
    xor ax, ax ; ax = 0
    mov es, ax
 
    not ax ; ax = 0xFFFF
    mov ds, ax
 
    mov di, 0x0500
    mov si, 0x0510
 
    mov al, byte [es:di]
    push ax
 
    mov al, byte [ds:si]
    push ax
 
    mov byte [es:di], 0x00
    mov byte [ds:si], 0xFF
 
    cmp byte [es:di], 0xFF
 
    pop ax
    mov byte [ds:si], al
 
    pop ax
    mov byte [es:di], al
 
    mov ax, 0
    je check_a20__exit
 
    mov ax, 1
 
check_a20__exit:
    pop si
    pop di
    pop es
    pop ds
    popf
 
    ret

; FIXME: not an error, qemu has it preeneabled though
a20_not_enabled:
    mov si, a20_is_not_enabled_str
    call print
    cli
    hlt


drive_num:
    db 0
startup_str:
    db "Loading operating system...",0
a20_is_not_enabled_str:
    db "A20 gate not enabled, stopping",0



align 16
gdt_r:
    dw gdt_end - gdt - 1
    dd gdt
align 16
gdt:
    dd 0 ; null entry
    dd 0
gdt_code_segment:
    dw 0xffff     ; limit (address range)
    dw 0x0000     ; base (address start)
    db 0          ; base next 8 bits
    db 0x9a       ; access byte
    db 11001111b   ; flags and upper 4 bits limit
    db 0          ; base next 8 bits
gdt_data_segment:
    dw 0xffff
    dw 0x0000
    db 0
    db 0x92
    db 11001111b
    db 0
gdt_end:

disk_packet:
    db 0x10     ; size of packet
    db 0x0      ; always 0
dp_num_sectors:
    dw 0x0040      ; sectors to transfer
dp_dest_offset:
    dw 0x0
dp_dest_segment:
    dw 0x0
dp_src_sector:
    dd 0x0      ; lower 32 source      
    dd 0x0      ; upper 16 source, +16 unused
    