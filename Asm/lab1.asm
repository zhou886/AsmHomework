.586
.model flat,stdcall
option casemap:none
includelib  msvcrt.lib
printf      PROTO C :ptr sbyte, :vararg
scanf       PROTO C :ptr sbyte, :vararg

.data
    inctrl  byte    "%s%s",0
    outCtrl byte    "%c",0
    outD    byte    "%d",0ah,0
    inStr1  byte    512 DUP(0)
    inStr2  byte    512 DUP(0)
    result  byte    1024 DUP(0)
    len1    dword   0
    len2    dword   0
    len3    dword   0
    tmp     dword   0
    i       dword   0
    j       dword   0

.code
start:
    invoke  scanf, offset inctrl, offset inStr1, offset inStr2
CountLen1:
    inc     len1
    mov     eax, len1
    add     eax, offset inStr1
    cmp     byte ptr [eax], 0
    jnz     CountLen1
CountLen2:
    inc     len2
    mov     eax, len2
    add     eax, offset inStr2
    cmp     byte ptr [eax], 0
    jnz     CountLen2

MulMainLoop:
    mov     tmp, 0
    mov     j, 0
MulSubLoop:
GetStr1I:
    mov     ebx, offset inStr1
    add     ebx, len1
    sub     ebx, i
    dec     ebx
    movzx   eax, byte ptr [ebx]
    sub     eax, 48
GetStr2J:
    mov     ebx, offset inStr2
    add     ebx, len2
    sub     ebx, j
    dec     ebx
    movzx   ebx, byte ptr [ebx]
    sub     ebx, 48
CountTmp:
    mul     ebx
    xor     edx, edx
    add     eax, tmp
    mov     ebx, offset result
    add     ebx, i
    add     ebx, j
    add     al, byte ptr[ebx]
    mov     ebx, 10
    div     ebx
    mov     ebx, offset result
    add     ebx, i
    add     ebx, j
    mov     byte ptr [ebx], dl
    mov     tmp, eax

    inc     j
    mov     ebx, j
    cmp     ebx, len2
    jnz     MulSubLoop

    mov     ebx, i
    add     ebx, len2
    add     ebx, offset result
    mov     edx, tmp
    mov     byte ptr [ebx], dl

    inc     i
    mov     eax, i
    cmp     eax, len1
    jnz     MulMainLoop

    mov     eax, len1
    add     eax, len2
CountLen3:
    mov     ebx, offset result
    add     ebx, eax
    cmp     eax, 0
    jz      GetLen3
    cmp     byte ptr [ebx], 0
    jnz     GetLen3
    dec     eax
    jmp     CountLen3
GetLen3:
    mov     len3, eax

OutputResult:
    mov     eax, len3
    mov     dl, byte ptr [eax+offset result]
    add     dl, 48
    invoke  printf, offset outCtrl, dl
    dec     len3
    mov     eax, len3
    cmp     eax, 0
    jnz     OutputResult
    
    mov     dl, result
    add     dl, 48
    invoke  printf, offset outCtrl, dl    
    invoke  printf, offset outCtrl, 0ah
end start