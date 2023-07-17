[bits 16]

; MBR, loads the boot sector off an ISO
; this is skipped if loaded with no-emulation

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
    mov WORD [dp_dest_segment],0x1000     ; load kernel at 0x10000 (128kb)
    mov WORD [dp_dest_offset],0
    mov WORD [dp_num_sectors],31       ;  load next 31 sectors (15.5kb)

    int 0x13
    jc disk_error

    ; FIXME:
    ; load x bytes from y sector, to get bootloader stage 2
    ; reposition stage 2 at 0x7c00
    ; jmp to 0x7c00

disk_error:
    mov si, disk_error_str
    call print
    cli
    hlt

extensions_not_supported:
    mov si, extensions_not_supported_str
    call print
    cli
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

drive_num:
    db 0
disk_error_str:
    db "DISK ERROR: ", 0
extensions_not_supported_str:
    db "BIOS EXTENSIONS NOT SUPPORTED", 0

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