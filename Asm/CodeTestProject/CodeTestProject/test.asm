.386
.model flat, stdcall
option casemap:none
includelib  msvcrt.lib
includelib  stdio.h
includelib  string.h
scanf       PROTO C :ptr sbyte, :vararg
printf      PROTO C :ptr sbyte, :vararg
fgets       PROTO C :ptr sbyte, :dword, :ptr dword
strcmp      PROTO C :ptr sbyte, :ptr sbyte
fopen       PROTO C :ptr sbyte, :ptr dword

.data
    inMsg       byte    "Please input the absolute path of files you want to compare:", 0ah, 0
    inCtrl      byte    "%s%s", 0
    outCtrl     byte    "line %d", 0ah, 0
    fileMode    byte    "r", 0
    ErrMsg1     byte    "Failed to open the source file 1!", 0ah, 0
    ErrMsg2     byte    "Failed to open the source file 2!", 0ah, 0
    succMsg     byte    "Two source files are same.", 0ah, 0
    src1        dword   0
    src2        dword   0
    str1        byte    512 DUP(0)
    str2        byte    512 DUP(0)
    res1        dword   0
    res2        dword   0
    line        word    1
    flag        byte    0

.code
start:
    invoke      scanf, offset inCtrl, offset str1, offset str2
    invoke      fopen, offset str1, offset fileMode
    mov         src1, eax
    cmp         eax, 0
    jnz         l1
    invoke      printf, offset ErrMsg1
    ret
l1: invoke      fopen, offset str2, offset fileMode
    mov         src2, eax
    cmp         eax, 0
    jnz         l2
    invoke      printf, offset ErrMsg2
    ret
l2: invoke      fgets, offset str1, 512, src1
    mov         res1, eax
    invoke      fgets, offset str2, 512, src2
    mov         res2, eax
    or          eax, res1
    cmp         eax, 0
    jz          l4
    invoke      strcmp, offset str1, offset str2
    cmp         eax, 0
    jz          l3
    invoke      printf, offset outCtrl, line
    mov         flag, 1
l3: inc         line
    jmp         l2
l4: mov         al, flag
    cmp         al, 0
    jnz         l5
    invoke      printf, offset succMsg
l5: ret
end start

