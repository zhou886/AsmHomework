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
scanf       PROTO C :ptr sbyte, :vararg
printf      PROTO C :ptr sbyte, :vararg
sprintf     PROTO C :ptr sbyte, :ptr sbyte, :vararg
fgets       PROTO C :ptr sbyte, :dword, :ptr dword
strcmp      PROTO C :ptr sbyte, :ptr sbyte
strcat      PROTO C :ptr sbyte, :ptr sbyte
fopen       PROTO C :ptr sbyte, :ptr dword

.data
    edit        byte    "edit", 0
    button      byte    "button", 0
    btnMsg      byte    "START", 0
    mainTitle   byte    "Comparator", 0
    CaptionName byte    "Comparator", 0
    inCtrl      byte    "%s%s", 0
    outCtrl     byte    "line %d", 0ah, 0
    fileMode    byte    "r", 0
    ErrMsg1     byte    "Failed to open the source file 1!", 0
    ErrMsg2     byte    "Failed to open the source file 2!", 0
    ErrMsgName  byte    "Error Messaga", 0
    succMsg     byte    "Two source files are same.", 0ah, 0
    succMsgName byte    "Reuslt", 0
    tmp         byte    10 DUP(0)
    src1        dword   0
    src2        dword   0
    str1        byte    512 DUP(0)
    str2        byte    512 DUP(0)
    result      byte    512 DUP(0)
    res1        dword   0
    res2        dword   0
    line        word    1
    flag        byte    0
    hEdit1      dword   0
    hEdit2      dword   0
    hBtn        dword   0
    hApp        dword   0
    hWin        dword   0


.code
Compare     proc
            invoke      GetWindowText, hEdit1, str1, 512
            invoke      GetWindowText, hEdit2, str2, 512
            invoke      fopen, offset str1, offset fileMode
            mov         src1, eax
            cmp         eax, 0
            jnz         l1
            invoke      MessageBox, 0, ErrMsg1, ErrMsgName, MB_OK
            ret
l1:
            invoke      fopen, offset str2, offset fileMode
            mov         src2, eax
            cmp         eax, 0
            jnz         l2
            invoke      MessageBox, 0, ErrMsg2, ErrMsgName, MB_OK
            ret
l2:
            invoke      fgets, offset str1, 512, src1
            mov         res1, eax
            invoke      fgets, offset str2, 512, src2
            mov         res2, eax
            or          eax, res1
            cmp         eax, 0
            jz          l4
            invoke      strcmp, offset str1, offset str2
            cmp         eax, 0
            jz          l3
            invoke      sprintf, offset tmp, offset outCtrl, line
            invoke      strcat, offset result, offset tmp
            mov         flag, 1
l3:
            inc         line
            jmp         l2
l4:
            mov         al, flag
            cmp         al, 0
            jnz         l5
            invoke      sprintf, offset result, offset succMsg
l5:
            invoke      MessageBox, 0, result, succMsgName, MB_OK
            ret
Compare endp

WndProc     proc        hwnd, message, wParam, lParam
            local       ps:PAINTSTRUCT, hdc:HDC
            mov         eax, message
            .IF eax==WM_CREATE
                invoke  CreateWindowEx, WS_EX_CLIENTEDGE, offset edit, 0, WS_CHILD OR WS_VISIBLE OR SS_CENTERIMAGE OR SS_CENTER OR WS_BORDER, 10, 10, 300, 20, hwnd, 10, hApp, 0
                mov     hEdit1, eax
                invoke  CreateWindowEx, WS_EX_CLIENTEDGE, offset edit, 0, WS_CHILD OR WS_VISIBLE OR SS_CENTERIMAGE OR SS_CENTER OR WS_BORDER, 10, 50, 300, 20, hwnd, 20, hApp, 0
                mov     hEdit2, eax
                invoke  CreateWindowEx, NULL, offset button, offset btnMsg, WS_CHILD OR WS_VISIBLE OR BS_FLAT OR WS_BORDER, 100, 90, 100, 20, hwnd, 30, hApp, 0
                mov     hBtn, eax
            .ELSEIF eax==WM_PAINT
                invoke  BeginPaint, hwnd, addr ps
                mov     hdc, eax
                invoke  EndPaint, hwnd, addr ps
            .ELSEIF eax==WM_DESTROY
                invoke  PostQuitMessage, 0
            .ELSEIF eax==WM_COMMAND
                mov     eax, wParam
                .IF eax==30
                    invoke Compare
                .ENDIF
            .ENDIF
            invoke      DefWindowProc, hwnd, message, wParam, lParam
WndProc endp

main        proc
            local       wndClass:WNDCLASSEX
            local       msg:MSG
            invoke      GetModuleHandle, NULL
            mov         hApp, eax

            invoke      RtlZeroMemory, addr wndClass, sizeof wndClass

            invoke      LoadCursor, 0, IDC_ARROW
            mov         wndClass.hCursor, eax
            mov         eax, hApp
            mov         wndClass.hInstance, eax
            mov         wndClass.cbSize, sizeof WNDCLASSEX
            mov         wndClass.style, CS_HREDRAW or CS_VREDRAW
            mov         wndClass.lpfnWndProc, offset WndProc
            mov         wndClass.hbrBackground, COLOR_WINDOW + 1
            mov         wndClass.lpszClassName, offset mainTitle

            invoke      RegisterClassEx, addr wndClass
            invoke      CreateWindowEx, WS_EX_CLIENTEDGE, offset mainTitle, offset CaptionName, WS_OVERLAPPEDWINDOW, 200, 200, 400, 200, NULL, NULL, hApp, NULL
            mov         hWin, eax

            invoke      ShowWindow, hWin, SW_SHOWNORMAL
            invoke      UpdateWindow, hWin

MAIN1:
            invoke      GetMessage, addr msg, NULL, 0, 0
            invoke      TranslateMessage, addr msg
            invoke      DispatchMessage, addr msg
            jmp         MAIN1

            invoke      ExitProcess, NULL
            ret
main endp
end main