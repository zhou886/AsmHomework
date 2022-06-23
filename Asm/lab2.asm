.386
.model flat, stdcall
option casemap:none
include     windows.inc
include     kernel32.inc
include     user32.inc
include     msvcrt.inc
includelib  kernel32.lib
includelib  user32.lib
includelib  msvcrt.lib
includelib  stdio.h
includelib  string.h
includelib  windows.h

sprintf     PROTO C :ptr byte, :ptr byte, :vararg
strlen      PROTO C :ptr byte
strcpy      PROTO C :ptr byte, :ptr byte
strchr      PROTO C :ptr byte, :byte
memset      PROTO C :ptr byte, :dword, :dword
isDigit     PROTO :byte
isOperator  PROTO :byte
isDot       PROTO :byte
Calculate   PROTO
RaiseError  PROTO :ptr byte
Clear       PROTO
Delete      PROTO
GetOperand  PROTO
ArrayToNumber           PROTO :ptr byte
AppendNumber            PROTO :ptr byte, :byte
AppendNumberToStatic    PROTO :dword
AppendOperatorToStatic  PROTO :dword
AppendDotToNumber       PROTO 
TriFuncCalculate        PROTO :dword

.data
    hWin        dword       0
    hApp        dword       0
    hStatic     dword       0
    hBtnOpr     dword       7 DUP(0)
    hBtnTriFun  dword       3 DUP(0)
    hBtnNum     dword       10 DUP(0)
    hBtnDot     dword       0
    hBtnClc     dword       0
    hBtnDel     dword       0
    strStaticBuffer byte    128 DUP(0)
    strNum1     byte        32 DUP(0)
    strNum2     byte        32 DUP(0)
    dNum1       real8       0.
    dNum2       real8       0.
    dRes        real8       0.
    dConst1     real8       1.0
    dConst10    real8       10.0
    dERR        real8       1.0e-8
    iOpr        dword       0
    iNum1       dword       0
    iNum2       dword       0
    iNumDot1    dword       0
    iNumDot2    dword       0
    strConstOpr byte        '+-*/%', 0
    strConstNum byte        '0123456789', 0
    strShow     byte        4 DUP(0)
    strOpr      byte        '+-*/%.=', 0
    strTriFun   byte        'sin', 0 , 'cos', 0, 'tan', 0
    ErrMsgName  byte        'Error Message', 0
    ErrDivZero  byte        'ERR! Dividing Zero!', 0ah, 0
    OutFormat0  byte        '%.0f', 0
    OutFormat5  byte        '%.5f', 0
    StaticName  byte        'static', 0
    BtnName     byte        'button', 0
    strCLC      byte        'CLC', 0
    strDEL      byte        'DEL', 0
    strAppName  byte        'Calculator', 0

.code
isDigit proc chr:byte
            movzx   eax, chr
            cmp     eax, 48 ;'0'
            jb      ID1
            cmp     eax, 57 ;'9'
            ja      ID1
            mov     eax, 1
            ret
ID1:
            mov     eax, 0
            ret
isDigit     endp

isDot proc chr:byte
            movzx   eax, chr
            cmp     eax, 46 ;'.'
            jnz     ID2
            mov     eax, 1
            ret
ID2:
            mov     eax, 0
            ret
isDot       endp

isOperator proc chr:byte
            invoke  strchr, offset strConstOpr, chr
            cmp     eax, 0
            jz      IO1
            mov     eax, 1
            ret
IO1:
            mov     eax, 0
            ret
isOperator  endp

AppendNumber proc uses eax ebx, src:ptr byte, chr:byte
            invoke  strlen, src
            mov     bl, chr
            add     eax, src
            mov     [eax], bl
            ret
AppendNumber endp

ArrayToNumber proc uses eax ecx, num:ptr byte
            local   i:dword
            local   len:dword
            local   ex:real8
            local   tmp:real8
            invoke  strlen, num
            mov     len, eax
            mov     i, 0
            finit
            fldz
            fst     dRes
            fst     ex
            fst     tmp
ATN1:
            mov     ecx, i
            cmp     ecx, len
            jae     ATN6
            add     ecx, num
            invoke  isDot, [ecx]
            cmp     eax, 0
            jz      ATN2
            finit
            fld1
            fdiv    dConst10
            fstp    ex
            jmp     ATN5
ATN2:
            finit
            fldz
            mov     eax, num
            add     eax, i
            mov     al, [eax]
            sub     al, 48
LOOP1:
            cmp     al, 0
            jz      ATN3
            fadd    dConst1
            dec     al
            jmp     LOOP1
ATN3:
            fstp    tmp
            finit
            fld     ex
            fldz
            fcom
            fnstsw  ax
            sahf
            jz      ATN4
            finit
            fld     tmp
            fmul    ex
            fadd    dRes
            fstp    dRes
            fld     ex
            fdiv    dConst10
            fstp    ex
            jmp     ATN5
ATN4:
            finit
            fld     dRes
            fmul    dConst10
            fadd    tmp
            fstp    dRes
ATN5:
            inc     i
            jmp     ATN1
ATN6:
            ret
ArrayToNumber endp

Clear proc
            invoke  memset, offset strStaticBuffer, 0, sizeof strStaticBuffer
            invoke  SetWindowText, hStatic, offset strStaticBuffer
            mov     iNum1, 0
            mov     iNum2, 0
            mov     iOpr, 0
            mov     iNumDot1, 0
            mov     iNumDot2, 0
            ret
Clear endp

Delete proc uses eax
            local   len:dword
            local   chr:byte
            invoke  GetWindowText, hStatic, offset strStaticBuffer, 128
            invoke  strlen, offset strStaticBuffer
            mov     len, eax
            dec     eax
            mov     al, [strStaticBuffer+eax]
            mov     chr, al
            ; fetch last char of strStaticBuffer to chr
            invoke  isOperator, chr
            cmp     eax, 0
            jz      D1
            mov     iOpr, 0
            jmp     D5
D1:
            invoke  isDot, chr
            cmp     eax, 0
            jz      D3
            mov     eax, iNum2
            cmp     eax, 1
            jnz     D2
            mov     iNumDot2, 0
            jmp     D5
D2:
            mov     iNumDot1, 0
            jmp     D5
D3:
            invoke  isDigit, chr
            cmp     eax, 0
            jz      D5
            mov     eax, len
            sub     eax, 2
            invoke  isOperator, [strStaticBuffer+eax]
            cmp     eax, 0
            jz      D4
            mov     iNum2, 0
D4:
            mov     eax, len
            cmp     eax, 1
            jnz     D5
            mov     iNum1, 0
D5:
            mov     eax, len
            dec     eax
            mov     [strStaticBuffer+eax], 0
            invoke  SetWindowText, hStatic, offset strStaticBuffer
            ret
Delete endp

RaiseError proc errmsg:ptr byte
            invoke MessageBox, NULL, errmsg, offset ErrMsgName, MB_OK
            ret
RaiseError endp

TriFuncCalculate proc uses eax ebx edx, num:dword
            mov     eax, iNum1
            cmp     eax, 0
            jz      TFC2
            mov     eax, iOpr
            cmp     eax, 0
            jnz     TFC1
            mov     eax, num
            sub     eax, 38
            add     eax, 6
            mov     iOpr, eax
            invoke  Calculate
            jmp     TFC2
TFC1:
            mov     eax, iNum2
            cmp     eax, 1
            jnz     TFC2
            invoke  Calculate
            mov     eax, num
            sub     eax, 38
            add     eax, 6
            mov     iOpr, eax
            invoke  Calculate
TFC2:
            ret
TriFuncCalculate endp

AppendDotToNumber proc uses eax
            local   len:dword
            invoke  GetWindowText, hStatic, offset strStaticBuffer, 128
            invoke  strlen, offset strStaticBuffer
            mov     len, eax
            mov     eax, iNum1
            cmp     eax, 1
            jnz     ADT1
            mov     eax, iOpr
            cmp     eax, 0
            jnz     ADT1
            mov     eax, iNumDot1
            cmp     eax, 0
            jnz     ADT1
            mov     iNumDot1, 1
            mov     eax, len
            mov     [strStaticBuffer+eax], 46
ADT1:
            mov     eax, iNum2
            cmp     eax, 1
            jnz     ADT2
            mov     eax, iNumDot2
            cmp     eax, 0
            jnz     ADT2
            mov     iNumDot2, 1
            mov     eax, len
            mov     [strStaticBuffer+eax], 46
ADT2:
            invoke  SetWindowText, hStatic, offset strStaticBuffer
            ret
AppendDotToNumber endp

AppendNumberToStatic proc uses eax ebx, num:dword
            local   len:dword
            invoke  GetWindowText, hStatic, offset strStaticBuffer, 128
            invoke  strlen, offset strStaticBuffer
            mov     len, eax
            mov     eax, iNum1
            cmp     eax, 0
            jnz     ANTS1
            mov     iNum1, 1
            jmp     ANTS2
ANTS1:
            mov     eax, iNum2
            cmp     eax, 0
            jnz     ANTS2
            mov     eax, iOpr
            cmp     eax, 0
            jz     ANTS2
            mov     iNum2, 1
ANTS2:
            mov     eax, num
            add     eax, 48
            mov     ebx, len
            mov     [strStaticBuffer+ebx], al
            invoke  SetWindowText, hStatic, offset strStaticBuffer
            ret
AppendNumberToStatic endp

AppendOperatorToStatic proc uses eax ebx, opr:dword
            local   len:dword
            mov     eax, iNum1
            cmp     eax, 0
            jz      AOTS2
            mov     eax, iNum2
            cmp     eax, 0
            jnz     AOTS1
            mov     eax, iOpr
            cmp     eax, 0
            jnz     AOTS1
            mov     eax, opr
            inc     eax
            mov     iOpr, eax
            invoke  GetWindowText, hStatic, offset strStaticBuffer, 128
            invoke  strlen, offset strStaticBuffer
            mov     len, eax
            mov     eax, opr
            mov     bl, [strConstOpr+eax]
            mov     eax, len
            mov     [strStaticBuffer+eax], bl
            invoke  SetWindowText, hStatic, offset strStaticBuffer
            jmp     AOTS2
AOTS1:
            mov     eax, iNum2
            cmp     eax, 0
            jz      AOTS2
            mov     eax, iOpr
            cmp     eax, 0
            jz      AOTS2
            invoke  Calculate
            mov     eax, opr
            inc     eax
            mov     iOpr, eax
            invoke  GetWindowText, hStatic, offset strStaticBuffer, 128
            invoke  strlen, offset strStaticBuffer
            mov     len, eax
            mov     eax, opr
            mov     bl, [strConstOpr+eax]
            mov     eax, len
            mov     [strStaticBuffer+eax], bl
            invoke  SetWindowText, hStatic, offset strStaticBuffer
AOTS2:
            ret
AppendOperatorToStatic endp

GetOperand proc uses eax ebx
            local   len:dword
            local   flag:dword
            local   i:dword
            invoke  memset, offset strNum1, 0, sizeof strNum1
            invoke  memset, offset strNum2, 0, sizeof strNum2
            invoke  GetWindowText, hStatic, offset strStaticBuffer, 128
            invoke  strlen, offset strStaticBuffer
            mov     len, eax
            mov     flag, 0
            mov     i, 0
GO1:
            mov     eax, i
            cmp     eax, len
            jae     GO6
            mov     al, [strStaticBuffer+eax]
            cmp     al, 46
            jz      GO2
            cmp     al, 48
            jb      GO4
            cmp     al, 57
            ja      GO4
GO2:
            mov     eax, flag
            cmp     eax, 0
            jnz     GO3
            invoke  strlen, offset strNum1
            mov     ebx, i
            mov     bl, [strStaticBuffer+ebx]
            mov     [strNum1+eax], bl
            jmp     GO5
GO3:
            invoke  strlen, offset strNum2
            mov     ebx, i
            mov     bl, [strStaticBuffer+ebx]
            mov     [strNum2+eax], bl
            jmp     GO5
GO4:
            mov     eax, i
            cmp     i, 0
            jz      GO5
            mov     flag, 1
GO5:
            inc     i
            jmp     GO1
GO6:
            finit
            invoke  ArrayToNumber, offset strNum1
            fld     dRes
            fstp    dNum1
            invoke  ArrayToNumber, offset strNum2
            fld     dRes
            fstp    dNum2
            mov     al, [strStaticBuffer]
            cmp     al, 45
            jnz     GO7
            fld     dNum1
            fchs
            fstp    dNum1
GO7:
            ret
GetOperand endp

Calculate proc uses eax ebx
            invoke  GetOperand
C1:
            mov     eax, iOpr
            cmp     eax, 1
            jnz     C2
            finit
            fld     dNum1
            fadd    dNum2
            fstp    dNum1
            jmp     C9
C2:
            mov     eax, iOpr
            cmp     eax, 2
            jnz     C3
            finit
            fld     dNum1
            fsub    dNum2
            fstp    dNum1
            jmp     C9
C3:
            mov     eax, iOpr
            cmp     eax, 3
            jnz     C4
            finit
            fld     dNum1
            fmul    dNum2
            fstp    dNum1
            jmp     C9
C4:
            mov     eax, iOpr
            cmp     eax, 4
            jnz     C5
            finit
            fld     dNum2
            fldz
            fcom
            fnstsw  ax
            sahf
            je      DIVZERO
            finit
            fld     dNum1
            fdiv    dNum2
            fstp    dNum1
            jmp     C9
DIVZERO:
            invoke  RaiseError, offset ErrDivZero
            ret
C5:
            mov     eax, iOpr
            cmp     eax, 5
            jnz     C6
            finit
            fld     dNum2
            fldz
            fcom
            fnstsw  ax
            sahf
            jz      DIVZERO
            finit
            fld     dNum2
            fld     dNum1
            fprem
            fstp    dNum1
            jmp     C9
C6:
            mov     eax, iOpr
            cmp     eax, 6
            jnz     C7
            finit
            fld     dNum1
            fsin
            fstp    dNum1
            jmp     C9
C7:
            mov     eax, iOpr
            cmp     eax, 7
            jnz     C8
            finit
            fld     dNum1
            fcos
            fstp    dNum1
            jmp     C9
C8:
            mov     eax, iOpr
            cmp     eax, 8
            jnz     C9
            finit
            fld     dNum1
            fcos
            fld     dNum1
            fsin
            fdiv    st(0), st(1)
            fstp    dNum1
C9:
            mov     iOpr, 0
            mov     iNum2, 0
            mov     iNumDot2, 0
            finit
            fldz
            fst     dNum2
            invoke  memset, offset strStaticBuffer, 0, sizeof strStaticBuffer
            finit
            fld     dNum1
            frndint
            fld     dNum1
            fsub
            fabs
            fcom    dERR
            fnstsw  ax
            sahf
            ja     C10
            mov     iNumDot1, 0
            invoke  sprintf, offset strStaticBuffer, offset OutFormat0, dNum1
            jmp     C11
C10:
            mov     iNumDot1, 1
            invoke  sprintf, offset strStaticBuffer, offset OutFormat5, dNum1
C11:
            invoke  strcpy, offset strNum1, offset strStaticBuffer
            invoke  SetWindowText, hStatic, offset strStaticBuffer
            ret
Calculate endp

WinProc proc hWnd, msg, wParam, lParam
            local   ps:PAINTSTRUCT
            local   rect:RECT
            local   hdc:HDC
            local   i:dword
            local   x:dword
            local   y:dword
            local   id:dword
CREATE:
            mov     eax, msg
            cmp     eax, WM_CREATE
            jnz     PAINT
            invoke  CreateWindowEx, NULL, offset StaticName, NULL, WS_CHILD or WS_VISIBLE or WS_BORDER or SS_CENTER or SS_CENTERIMAGE, 15, 10, 290, 50, hWnd, 100, hApp, NULL
            mov     hStatic, eax
            mov     i, 0
WP1:
            mov     eax, i
            cmp     eax, 10
            jae     WP2
            mov     al, strConstNum[eax]
            mov     [strShow], al
            mov     edx, 0
            mov     eax, i
            mov     ebx, 5
            div     ebx
            mov     eax, edx
            mov     edx, 0
            mov     ebx, 60
            mul     ebx
            add     eax, 15
            mov     x, eax
            mov     edx, 0
            mov     eax, i
            mov     ebx, 5
            div     ebx
            mov     ebx, 60
            mul     ebx
            add     eax, 80
            mov     y, eax
            invoke  CreateWindowEx, NULL, offset BtnName, offset strShow, WS_CHILD or WS_VISIBLE or WS_BORDER or BS_FLAT, x, y, 50, 50, hWnd, i, hApp, NULL
            mov     ebx, i
            mov     [hBtnNum+ebx], eax
            inc     i
            jmp     WP1
WP2:
            mov     i, 0
WP3:
            mov     eax, i
            cmp     eax, 7
            jae     WP4
            mov     al, strOpr[eax]
            mov     [strShow], al
            mov     eax, i
            mov     edx, 0
            mov     ebx, 5
            div     ebx
            mov     eax, edx
            mov     ebx, 60
            mul     ebx
            add     eax, 15
            mov     x, eax
            mov     eax, i
            mov     edx, 0
            mov     ebx, 5
            div     ebx
            mov     ebx, 60
            mul     ebx
            add     eax, 200
            mov     y, eax
            mov     eax, i
            add     eax, 10
            mov     id, eax
            invoke  CreateWindowEx, NULL, offset BtnName, offset strShow, WS_CHILD or WS_VISIBLE or WS_BORDER or BS_FLAT, x, y, 50, 50, hWnd, id, hApp, NULL
            mov     ebx, i
            mov     [hBtnOpr+ebx], eax
            inc     i
            jmp     WP3
WP4:
            mov     i, 0
WP5:
            mov     eax, i
            cmp     eax, 3
            jae     WP6
            mov     ebx, 4
            mul     ebx
            add     eax, offset strTriFun
            invoke  strcpy, offset strShow, eax
            mov     eax, i
            mov     ebx, 60
            mul     ebx
            add     eax, 135
            mov     x, eax
            mov     eax, i
            add     eax, 38
            mov     id, eax
            invoke  CreateWindowEx, NULL, offset BtnName, offset strShow, WS_CHILD or WS_VISIBLE or WS_BORDER or BS_FLAT, x, 260, 50, 50, hWnd, id, hApp, NULL
            mov     ebx, i
            mov     hBtnTriFun[ebx], eax
            inc     i
            jmp     WP5
WP6:
            invoke  CreateWindowEx, NULL, offset BtnName, offset strCLC, WS_CHILD or WS_VISIBLE or WS_BORDER or BS_FLAT, 15, 320, 140, 50, hWnd, 50, hApp, NULL
            mov     hBtnClc, eax

            invoke  CreateWindowEx, NULL, offset BtnName, offset strDEL, WS_CHILD or WS_VISIBLE or WS_BORDER or BS_FLAT, 165, 320, 140, 50, hWnd, 54, hApp, NULL
            mov     hBtnDel, eax
PAINT:
            mov     eax, msg
            cmp     eax, WM_PAINT
            jnz     CLOSE
            invoke  BeginPaint, hWnd, addr ps
            mov     hdc, eax
            invoke  EndPaint, hWnd, addr ps
CLOSE:
            mov     eax, msg
            cmp     eax, WM_CLOSE
            jnz     COMMAND
            invoke  DestroyWindow, hWin
            invoke  PostQuitMessage, NULL
COMMAND:
            mov     eax, msg
            cmp     eax, WM_COMMAND
            jnz     RETURN
NUMBER:
            mov     eax, wParam
            cmp     eax, 0
            jb      RETURN
            cmp     eax, 9
            ja      OPERATOR
            invoke  AppendNumberToStatic, eax
            jmp     RETURN
OPERATOR:
            mov     eax, wParam
            cmp     eax, 14
            ja      DOT
            sub     eax, 10
            invoke  AppendOperatorToStatic, eax
            jmp     RETURN
DOT:
            mov     eax, wParam
            cmp     eax, 15
            jnz     CAL
            invoke  AppendDotToNumber
            jmp     RETURN
CAL:
            mov     eax, wParam
            cmp     eax, 16
            jnz     TRIFUN
            invoke  Calculate
            jmp     RETURN
TRIFUN:
            mov     eax, wParam
            cmp     eax, 38
            jb      CLC1
            cmp     eax, 46
            ja      CLC1
            invoke  TriFuncCalculate, eax
            jmp     RETURN
CLC1:
            mov     eax, wParam
            cmp     eax, 50
            jnz     DEL
            invoke  Clear
            jmp     RETURN
DEL:
            mov     eax, wParam
            cmp     eax, 54
            jnz     RETURN
            invoke  Delete
RETURN:
            invoke  DefWindowProc, hWnd, msg, wParam, lParam
            ret
WinProc endp

main        proc
            local       wndClass:WNDCLASSEX
            local       msg:MSG            
            invoke      RtlZeroMemory, addr wndClass, sizeof wndClass
            invoke      GetModuleHandle, NULL
            mov         hApp, eax
            mov         wndClass.hInstance, eax
            mov         wndClass.cbSize, sizeof WNDCLASSEX
            mov         wndClass.style, CS_HREDRAW or CS_VREDRAW
            mov         wndClass.lpfnWndProc, offset WinProc
            mov         wndClass.hbrBackground, COLOR_WINDOW + 1
            mov         wndClass.lpszClassName, offset strAppName
            invoke      LoadCursor, 0, IDC_ARROW
            mov         wndClass.hCursor, eax

            invoke      RegisterClassEx, addr wndClass
            invoke      CreateWindowEx, WS_EX_CLIENTEDGE, offset strAppName, offset strAppName, WS_OVERLAPPEDWINDOW, 0, 0 ,335, 420, NULL, NULL, hApp, NULL
            mov         hWin, eax
            invoke      ShowWindow, hWin, SW_SHOWNORMAL
            invoke      UpdateWindow, hWin

MAIN1:
            invoke      GetMessage, addr msg, NULL, 0, 0
            cmp         eax, 0
            jz          MAIN2
            invoke      TranslateMessage, addr msg
            invoke      DispatchMessage, addr msg
            jmp         MAIN1
MAIN2:
            invoke      ExitProcess, NULL
            ret
main        endp
end         main