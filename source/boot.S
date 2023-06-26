[bits 16]

ORG 0x7c00
section .text

global _start
_start:
    cli

; Initialize segments
    jmp 0:go       ; ensure cs = 0
go:   
    xor ax,ax
    mov ds, ax          ; set ds=0
    mov ax, 0x07E0      ; 07E0h = (07C00h+200h)/10h, beginning of stack segment.
    mov ss, ax
    mov sp, 0x2000      ; 8k of stack space.

    mov [drive_num], dl   ; save drive number from bios

    sti
    
    ; init screen
    call clearscreen
    mov dx, 0
    call movecursor

    ; check if bios extensions are available
    mov ah, 0x41
    mov bx, 0x55aa
    mov dl, 0x80
    int 0x13
    jc extensions_not_supported

    ; use int 13h to read kernel sectors off disk
    mov ah, 0x42
    mov bx, 0x55aa
    mov dl, [drive_num]
    mov si, disk_packet

    mov DWORD [dp_src_sector],1             
    mov WORD [dp_dest_segment],0x1000     ; load kernel at physical address 0x1'00'00
    mov WORD [dp_dest_offset],0
    mov WORD [dp_num_sectors],17       ;  load 9 sectors

    int 0x13
    jc disk_error

    ; enable a20 to go to protected mode
    call check_a20
    cmp ax, 1
    jne a20_not_preenabled


    mov esi,welcome_msg
    call print

    ; setup GDT and IDT
    cli
    lgdt [gdt_r]
    mov eax, cr0
    or eax, 1
    mov cr0,eax         ; set protection ebaled

    jmp 0x8:.entry_32   ; 8=offset in gdt for code entry

[bits 32]
.entry_32:
    mov ax,0x10  ; data entry is offset 16 bytes in GDT
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov gs,ax
    mov ss,ax

    jmp 0x10000 ; take jump to kernel entry
    hlt
[bits 16]

; FIXME: not an error, qemu has it preeneabled though
a20_not_preenabled:
    mov si, a20_enabled_str
    call print
    cli
    hlt

disk_error:
    shr ax, 8
    push ax

    mov si, disk_error_str
    call print

    ; error code on stack
    ;call print_address

    cli
    hlt

extensions_not_supported:
    mov si, extensions_not_supported_str
    call print
    cli
    hlt

clearscreen:
    mov ah, 0x07        ; tells BIOS to scroll down window
    mov al, 0x00        ; clear entire window
    mov bh, 0x07        ; white on black
    mov cx, 0x00        ; specifies top left of screen as (0,0)
    mov dh, 0x18        ; 18h = 24 rows of chars
    mov dl, 0x4f        ; 4fh = 79 cols of chars
    int 0x10        ; calls video interrupt
    ret

; set cursor to DH/DL
movecursor:
    mov ah, 0x02        ; set cursor position
    mov bh, 0x00        ; page 0 - doesn't matter, we're not using double-buffering
    int 0x10
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

; converts 1 byte to hex character, returns eax
;int_to_hex:
;    push bp
;    mov bp, sp
;
;    xor eax,eax
;    mov al, [bp+4]
;    cmp al,9
;    jg .b1
;    add al, '0'
;    jmp .b2
;    .b1:
;    sub al, 10
;    add al, 'A'
;    .b2:
;
;    mov sp, bp
;    pop bp
;    ret
;
;print_address:
;    push bp         ; caller base stack pointer
;    mov bp, sp      ; base pointer = stack pointer
;    sub sp, 4       ; 4 bytes local variables
;
;    mov ax, [bp+4]
;    mov word [bp-2], ax
;    mov byte [bp-3], 0
;
;.loop_start:
;    cmp byte [bp-3], 4
;    jnl .loop_end
;
;    xor eax, eax
;    mov ax, word [bp-2]
;    and ax, 0xf000
;    shr ax, 12
;
;    push ax
;    call int_to_hex
;    add sp,2
;    ; return value in eax
;    
;    mov bh, 0x00        ; page number, 0 again
;    mov bl, 0x00        ; foreground color, irrelevant - in text mode
;    mov ah, 0x0E        ; print character to TTY
;    int 0x10            ; print the character if we're not done
;    
;    mov ax, word[bp-2]
;    shl ax, 4
;    mov word[bp-2], ax
;    mov al,byte[bp-3]
;    add al, 1
;    mov byte[bp-3], al
;    jmp .loop_start 
;.loop_end:
;    mov sp, bp
;    pop bp
;    ret

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

drive_num:
    db 0
welcome_msg:
    db "Starting boot", 0
disk_error_str:
    db "DISK ERROR: ", 0
extensions_not_supported_str:
    db "BIOS EXTENSIONS NOT SUPPORTED", 0
a20_enabled_str:
    db "A20 NOT PREENABLED", 0

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

times 510-($-$$) db 0
dw 0xAA55