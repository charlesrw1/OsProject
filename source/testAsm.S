extern printf
 
section .data       
 
    msg db "Hello world!!!!!", 0 
 
section .text           
        global main     
main:               
 
    mov rdi,msg
    mov rax,0       
    call printf wrt ..plt     
 
    mov rax,0       
    ret 