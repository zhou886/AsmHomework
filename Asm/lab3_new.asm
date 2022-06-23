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
scanf       PROTO C :ptr byte, :vararg
printf      PROTO C :ptr byte, :vararg
sprintf     PROTO C :ptr byte, :ptr byte, :vararg
strcmp      PROTO C :ptr byte, :ptr byte
strcat      PROTO C :ptr byte, :ptr byte
fopen       PROTO C :ptr byte, :ptr dword
fgets       PROTO C :ptr byte, :dword, :ptr dword
memset      PROTO C :ptr byte, :dword, :dword

.data
    EditName        byte        "edit", 0
    BtnName         byte        "button", 0
    BtnMsg          byte        "Start Comparing", 0
    AppName         byte        "Comparator", 0
    OutputFormat    byte        "line %d", 0ah, 0
    FileMode        byte        "r", 0
    ErrMsg1         byte        "Failed to open the source file 1!", 0
    ErrMsg2         byte        "Failed to open the source file 2!", 0
    ErrName         byte        "Error Message", 0
    succMsg         byte        "The two source files are exactly the same", 0ah, 0
    succName        byte        "Result", 0
    hEdit1          dword       0
    hEdit2          dword       0
    hBtn            dword       0
    hApp            dword       0
    hWin            dword       0
    tmp             byte        10 DUP(0)
    src1            dword       0
    src2            dword       0
    str1            byte        512 DUP(0)
    str2            byte        512 DUP(0)
    result          byte        512 DUP(0)
    res1            dword       0
    res2            dword       0
    line            word        1
    flag            byte        0


.code
CompareProc proc
            mov         line, 1
            invoke      memset, offset result, 0, sizeof result
            invoke      GetWindowText, hEdit1, offset str1, 512
            invoke      GetWindowText, hEdit2, offset str2, 512
            invoke      fopen, offset str1, offset FileMode
            mov         src1, eax
            cmp         eax, 0
            jnz         l1
            invoke      MessageBox, hWin, offset ErrMsg1, offset ErrName, MB_OK
            ret
l1:
            invoke      fopen, offset str2, offset FileMode
            mov         src2, eax
            cmp         eax, 0
            jnz         l2
            invoke      MessageBox, hWin, offset ErrMsg2, offset ErrName, MB_OK
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
            invoke      sprintf, offset tmp, offset OutputFormat, line
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
            invoke      MessageBox, hWin, offset result, offset succName, MB_OK
            ret
CompareProc endp

WinProc     proc        hWnd, msg, wParam, lParam
            local       ps:PAINTSTRUCT
            local       rect:RECT
            local       hdc: HDC
CREATE:
            mov         eax, msg
            cmp         eax, WM_CREATE
            jnz         PAINT
            invoke      CreateWindowEx, NULL, offset BtnName, offset BtnMsg, WS_CHILD or WS_VISIBLE, 120, 100, 150, 25, hWnd, 15, hApp, NULL
            mov         hBtn, eax
            invoke      CreateWindowEx, WS_EX_CLIENTEDGE, offset EditName, 0, WS_CHILD or WS_BORDER or WS_VISIBLE, 10, 10, 350, 35, hWnd, 1, hApp, NULL
            mov         hEdit1, eax
            invoke      CreateWindowEx, WS_EX_CLIENTEDGE, offset EditName, 0, WS_CHILD or WS_BORDER or WS_VISIBLE, 10, 50, 350, 35, hWnd, 2, hApp, NULL
            mov         hEdit2, eax
PAINT:
            mov         eax, msg
            cmp         eax, WM_PAINT
            jnz         CLOSE
            invoke      BeginPaint, hWnd, addr ps
            mov         hdc, eax
            invoke      EndPaint, hWnd, addr ps
CLOSE:
            mov         eax, msg
            cmp         eax, WM_CLOSE
            jnz         COMMAND
            invoke      DestroyWindow, hWin
            invoke      PostQuitMessage, NULL
COMMAND:
            mov         eax, msg
            cmp         eax, WM_COMMAND
            jnz         RETURN
            mov         eax, wParam
            cmp         eax, 15
            jnz         RETURN
            invoke      CompareProc
RETURN:
            invoke      DefWindowProc, hWnd, msg, wParam, lParam
            ret
WinProc     endp

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
            mov         wndClass.lpszClassName, offset AppName
            invoke      LoadCursor, 0, IDC_ARROW
            mov         wndClass.hCursor, eax

            invoke      RegisterClassEx, addr wndClass
            invoke      CreateWindowEx, WS_EX_CLIENTEDGE, offset AppName, offset AppName, WS_OVERLAPPEDWINDOW, 0, 0 ,400 ,200, NULL, NULL, hApp, NULL
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