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
    in al, 0x92
    or al, 2
    out 0x92, al
    call check_a20
    cmp ax, 1
    jne a20_not_enabled

    ; get drive information
    mov ah, 0x48
    mov dl, [drive_num]
    mov si, drive_parameters_buffer
    int 0x13
    
    jnc .skip1
    mov si, couldnt_read_drive_param_str
    jmp other_error
.skip1:

    ; get memory information
    call detect_memory
    jnc .skip2
    mov [mem_map_count], word 0xffff
.skip2:

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

; called by protected mode code to issue bios calls
; arg1 = int bios_call_type
extern bios_call
bits 32
bios_call:
    push ebp
    mov ebp, esp
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi


    cli

    mov eax,esp
    mov [saved_stack_ptr], eax

    jmp 0x18:.protected16bit    ; 16b code seg
bits 16
.protected16bit:
    mov ax, 0x20    ; gdt 16b data seg
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov gs,ax
    mov ss,ax

    mov eax, cr0
    and eax, ~1
    mov cr0, eax

    jmp 0:.realmode
.realmode:
    xor ax,ax
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov gs,ax
    mov ss,ax
    mov sp, 0xf00  ; set temporary stack pointer

    mov bx,[bp+8]    ; arg1

    mov ax, 0
    cmp bx,ax
    je .do_disk_transfer

    ; can add more later if needed
    jmp .finish_bios_call

.do_disk_transfer:
    mov ah, 0x42
    mov dl, [drive_num]
    mov si, disk_packet
    int 0x13    ; call extended read
    jmp .finish_bios_call

.finish_bios_call:
; now go back to protected mode
    lgdt [gdt_r]
    mov eax, cr0
    or eax, 1
    mov cr0,eax         ; set protection ebaled
    jmp 0x8:.back_to_pmode

bits 32
.back_to_pmode:
    mov ax,0x10
    mov ds,ax
    mov es,ax
    mov fs,ax
    mov gs,ax
    mov ss,ax

    mov eax, [saved_stack_ptr]
    mov esp, eax

    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop ebp
    pop ebp
    
    ret

bits 16

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

; from osdev wiki
; uses int 15h, eax e820h
mem_map_entry equ 0x1000
detect_memory:
    mov di, mem_map_entry          ; Set di to 0x8004. Otherwise this code will get stuck in `int 0x15` after some entries are fetched 
	xor ebx, ebx		; ebx must be 0 to start
	xor bp, bp		; keep an entry count in bp
	mov edx, 0x0534D4150	; Place "SMAP" into edx
	mov eax, 0xe820
	mov [es:di + 20], dword 1	; force a valid ACPI 3.X entry
	mov ecx, 24		; ask for 24 bytes
	int 0x15
	jc short .fail	; carry set on first call means "unsupported function"
	mov edx, 0x0534D4150	; Some BIOSes apparently trash this register?
	cmp eax, edx		; on success, eax must have been reset to "SMAP"
	jne short .fail
	test ebx, ebx		; ebx = 0 implies list is only 1 entry long (worthless)
	je short .fail
	jmp short .jmpin
.memloop:
    mov eax, 0xe820
	mov [es:di + 20], dword 1
	mov ecx, 24
	int 0x15
	jc .finish
	mov edx, 0x0534D4150
.jmpin:
	jcxz .skipent
	cmp cl, 20
	jbe .notext
	test byte [es:di + 20], 1
	je .skipent
.notext:
	mov ecx, [es:di + 8]
	or ecx, [es:di + 12]
	jz .skipent
	inc bp
	add di, 24
.skipent:
	test ebx, ebx
	jne .memloop
.finish:
    mov [mem_map_count], bp
    clc
    ret
.fail:
    stc
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
other_error:
    call print
    cli
    hlt

section .data

extern mem_map_count
mem_map_count:
    dw 0

saved_stack_ptr:
    dw 0

extern drive_bytes_per_sector
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

extern drive_num
drive_num:
    db 0
startup_str:
    db "Loading operating system...",0
a20_is_not_enabled_str:
    db "A20 gate not enabled, stopping",0
couldnt_read_drive_param_str:
    db "Error reading drive params",0



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
; 16bit code segment 
    dw 0xffff
    dw 0
    db 0
    db 0x9e
    db 0
    db 0
; 16 bit data segment
    dw 0xffff
    dw 0
    db 0
    db 0x92
    db 0
    db 0
gdt_end:

extern dp_num_sectors
extern dp_dest_offset
extern dp_dest_segment
extern dp_src_sector
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
    