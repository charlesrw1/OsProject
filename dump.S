int kernel_main(int a)
{
   0:   f3 0f 1e fa             endbr64 
   4:   55                      push   rbp
   5:   48 89 e5                mov    rbp,rsp
   8:   48 81 ec 30 01 00 00    sub    rsp,0x130
   f:   89 bd dc fe ff ff       mov    DWORD PTR [rbp-0x124],edi
  15:   64 48 8b 04 25 28 00    mov    rax,QWORD PTR fs:0x28
  1c:   00 00 
  1e:   48 89 45 f8             mov    QWORD PTR [rbp-0x8],rax
  22:   31 c0                   xor    eax,eax
        char buffer[256];
        int i=0;
  24:   c7 85 ec fe ff ff 00    mov    DWORD PTR [rbp-0x114],0x0
  2b:   00 00 00 
        while(a>0)
  2e:   eb 69                   jmp    99 <kernel_main+0x99>
        {
                buffer[i++]=a%10;
  30:   8b 8d dc fe ff ff       mov    ecx,DWORD PTR [rbp-0x124]
  36:   48 63 c1                movsxd rax,ecx
  39:   48 69 c0 67 66 66 66    imul   rax,rax,0x66666667
  40:   48 c1 e8 20             shr    rax,0x20
  44:   89 c2                   mov    edx,eax
  46:   c1 fa 02                sar    edx,0x2
  49:   89 c8                   mov    eax,ecx
  4b:   c1 f8 1f                sar    eax,0x1f
  4e:   29 c2                   sub    edx,eax
  50:   89 d0                   mov    eax,edx
  52:   c1 e0 02                shl    eax,0x2
  55:   01 d0                   add    eax,edx
  57:   01 c0                   add    eax,eax
  59:   29 c1                   sub    ecx,eax
  5b:   89 ca                   mov    edx,ecx
  5d:   8b 85 ec fe ff ff       mov    eax,DWORD PTR [rbp-0x114]
  63:   8d 48 01                lea    ecx,[rax+0x1]
  66:   89 8d ec fe ff ff       mov    DWORD PTR [rbp-0x114],ecx
  6c:   48 98                   cdqe   
  6e:   88 94 05 f0 fe ff ff    mov    BYTE PTR [rbp+rax*1-0x110],dl
                a = a / 10;
  75:   8b 85 dc fe ff ff       mov    eax,DWORD PTR [rbp-0x124]
  7b:   48 63 d0                movsxd rdx,eax
  7e:   48 69 d2 67 66 66 66    imul   rdx,rdx,0x66666667
  85:   48 c1 ea 20             shr    rdx,0x20
  89:   c1 fa 02                sar    edx,0x2
  8c:   c1 f8 1f                sar    eax,0x1f
  8f:   29 c2                   sub    edx,eax
  91:   89 d0                   mov    eax,edx
  93:   89 85 dc fe ff ff       mov    DWORD PTR [rbp-0x124],eax
        while(a>0)
  99:   83 bd dc fe ff ff 00    cmp    DWORD PTR [rbp-0x124],0x0
  a0:   7f 8e                   jg     30 <kernel_main+0x30>
        }
        buffer[i]='\0';
  a2:   8b 85 ec fe ff ff       mov    eax,DWORD PTR [rbp-0x114]
  a8:   48 98                   cdqe   
  aa:   c6 84 05 f0 fe ff ff    mov    BYTE PTR [rbp+rax*1-0x110],0x0
  b1:   00 

        printf("%s\n", buffer);
  b2:   48 8d 85 f0 fe ff ff    lea    rax,[rbp-0x110]
  b9:   48 89 c7                mov    rdi,rax
  bc:   e8 00 00 00 00          call   c1 <kernel_main+0xc1>

        return 0;
  c1:   b8 00 00 00 00          mov    eax,0x0
  c6:   48 8b 75 f8             mov    rsi,QWORD PTR [rbp-0x8]
  ca:   64 48 33 34 25 28 00    xor    rsi,QWORD PTR fs:0x28
  d1:   00 00 
  d3:   74 05                   je     da <kernel_main+0xda>
  d5:   e8 00 00 00 00          call   da <kernel_main+0xda>
  da:   c9                      leave  
  db:   c3                      ret    