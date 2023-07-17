bits 16

; MBR, loads the boot sector off an ISO
; this is skipped if loaded with no-emulation

; BOOT_LOAD_SIZE and BOOT_LOAD_ADDR are pasted during build

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
    mov ss, ax
    mov sp, 0x7b00
    mov [drive_num], dl   ; save drive number from bios
    sti

    ; check if bios extensions are available
    mov ah, 0x41
    mov bx, 0x55aa
    mov dl, 0x80
    int 0x13
    jc extensions_not_supported

    ; get drive parameters
    mov ah, 0x48
    mov dl, [drive_num]
    mov si, drive_parameters_buffer
    int 0x13
    jc gen_err
    
    xor eax,eax
    xor edx, edx
    mov ax, BOOT_LOAD_ADDR
    mov cx, [drive_bytes_per_sector]
    div cx
    mov [dp_src_sector], eax
    mov ax, BOOT_LOAD_SIZE
    div cx

    mov [dp_num_sectors], ax
    mov WORD [dp_dest_offset], 0x7e00   ; use 7e00 as moving buffer
    mov ah, 0x42
    mov dl, [drive_num]
    mov si, disk_packet
    int 0x13    ; call extended read
    jc disk_error

    xor ax, ax
    mov es, ax
    mov ds, ax
    mov si, reposition
    mov di, 0x7b00
    mov cx, (reposition_end-reposition)
    rep movsb
    
    mov ax, 0x7b00
    jmp eax

reposition:
    mov si, 0x7e00
    mov di, 0x7c00
    mov cx, BOOT_LOAD_SIZE
    rep movsb
    mov ax, 0x7c00

    jmp eax    ; jump to the next stage
reposition_end:


disk_error:
    shr ax, 8
    push ax
    mov si, disk_error_str
    call print
    call print_address
    cli
    hlt

extensions_not_supported:
    mov si, extensions_not_supported_str
    call print
    cli
    hlt
other_error:
    mov si, gen_err
    call print
    cli
    hlt

;converts 1 byte to hex character, returns eax
int_to_hex:
    push bp
    mov bp, sp

    xor eax,eax
    mov al, [bp+4]
    cmp al,9
    jg .b1
    add al, '0'
    jmp .b2
    .b1:
    sub al, 10
    add al, 'A'
    .b2:

    mov sp, bp
    pop bp
    ret

print_address:
    push bp         ; caller base stack pointer
    mov bp, sp      ; base pointer = stack pointer
    sub sp, 4       ; 4 bytes local variables

    mov ax, [bp+4]
    mov word [bp-2], ax
    mov byte [bp-3], 0

.loop_start:
    cmp byte [bp-3], 4
    jnl .loop_end

    xor eax, eax
    mov ax, word [bp-2]
    and ax, 0xf000
    shr ax, 12

    push ax
    call int_to_hex
    add sp,2
    ; return value in eax
    
    mov bh, 0x00        ; page number, 0 again
    mov bl, 0x00        ; foreground color, irrelevant - in text mode
    mov ah, 0x0E        ; print character to TTY
    int 0x10            ; print the character if we're not done
    
    mov ax, word[bp-2]
    shl ax, 4
    mov word[bp-2], ax
    mov al,byte[bp-3]
    add al, 1
    mov byte[bp-3], al
    jmp .loop_start 
.loop_end:
    mov sp, bp
    pop bp
    ret


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

drive_parameters_buffer:
    dw 0x1e
    dw 0
    dd 0
    dd 0
    dd 0
    dq 0
drive_bytes_per_sector:
    dw 0
    dd 0


drive_num:
    db 0
disk_error_str:
    db "DISK ERROR: ", 0
extensions_not_supported_str:
    db "BIOS EXTENSIONS NOT SUPPORTED", 0
gen_err:
    db "ERROR OCCURED",0
all_good_str:
    db "ALL GOOD :)",0

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