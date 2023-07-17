bits 16

; jumped to from boot1.S
; in real mode
; read memory information
; switch to protected mode
; go to c code to search filesystem/load the kernel from the disk
;   jumps to kernel which will be loaded at 1MB
