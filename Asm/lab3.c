#include <stdio.h>
#include <string.h>
#include <windows.h>

HINSTANCE hInst;
char str1[100], str2[100], res[100];
HWND hEdit1, hEdit2, hBtn;

LRESULT CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM);
int compare();

int WINAPI WinMain(
    HINSTANCE hInstance,
    HINSTANCE hPrevInstance,
    PSTR szCmdLine,
    int iCmdShow)
{
    static TCHAR szClassName[] = TEXT("Comparator");
    HWND hwnd;
    MSG msg;
    WNDCLASS wndclass;

    hInst = hInstance;

    wndclass.style = CS_HREDRAW | CS_VREDRAW;
    wndclass.lpfnWndProc = WndProc;
    wndclass.cbClsExtra = 0;
    wndclass.cbWndExtra = 0;
    wndclass.hInstance = hInstance;
    wndclass.hIcon = LoadIcon(NULL, IDI_APPLICATION);
    wndclass.hCursor = LoadCursor(NULL, IDC_ARROW);
    wndclass.hbrBackground = (HBRUSH)GetStockObject(WHITE_BRUSH);
    wndclass.lpszMenuName = NULL;
    wndclass.lpszClassName = szClassName;

    RegisterClass(&wndclass);

    hwnd = CreateWindow(
        szClassName,
        TEXT("Comparator"),
        WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT,
        CW_USEDEFAULT,
        340,
        180,
        NULL,
        NULL,
        hInstance,
        NULL);

    ShowWindow(hwnd, iCmdShow);
    UpdateWindow(hwnd);

    while (GetMessage(&msg, NULL, 0, 0))
    {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    return msg.wParam;
}

LRESULT CALLBACK WndProc(
    HWND hwnd,
    UINT message,
    WPARAM wParam,
    LPARAM lParam)
{
    PAINTSTRUCT ps;
    HDC hdc;
    int id = 0;
    switch (message)
    {
    case WM_CREATE:
        hEdit1 = CreateWindow(TEXT("edit"), NULL,
                              WS_CHILD | WS_VISIBLE | SS_CENTERIMAGE | SS_CENTER | WS_BORDER,
                              10, 10, 300, 20, hwnd, (HMENU)10, hInst, NULL);
        hEdit2 = CreateWindow(TEXT("edit"), NULL,
                              WS_CHILD | WS_VISIBLE | SS_CENTERIMAGE | SS_CENTER | WS_BORDER,
                              10, 50, 300, 20, hwnd, (HMENU)20, hInst, NULL);
        hBtn = CreateWindow(TEXT("button"), TEXT("start"),
                            WS_CHILD | WS_VISIBLE | WS_BORDER | BS_FLAT,
                            100, 90, 100, 20, hwnd, (HMENU)30, hInst, NULL);
        break;
    case WM_PAINT:
        hdc = BeginPaint(hwnd, &ps);
        EndPaint(hwnd, &ps);
        break;
    case WM_DESTROY:
        PostQuitMessage(0);
        break;
    case WM_COMMAND:
        id = LOWORD(wParam);
        if (id == 30)
        {
            compare();
        }
    }
    return DefWindowProc(hwnd, message, wParam, lParam);
}

int compare()
{
    FILE *src1, *src2;
    int flag = 0;
    GetWindowText(hEdit1, str1, 100);
    GetWindowText(hEdit2, str2, 100);
    src1 = fopen(str1, "r");
    src2 = fopen(str2, "r");
    if (src1 == NULL)
    {
        MessageBox(NULL, "Failed to open the source file 1!", "Error Message", MB_OK);
        return 0;
    }
    if (src2 == NULL)
    {
        MessageBox(NULL, "Failed to open the source file 2!", "Error Message", MB_OK);
        return 0;
    }
    int line = 1;
    while (1)
    {
        char *r1 = fgets(str1, 512, src1), *r2 = fgets(str2, 512, src2);
        if (r1 == NULL && r2 == NULL)
        {
            break;
        }
        if (strcmp(str1, str2) != 0)
        {
            char tmp[10];
            sprintf(tmp, "Line %d\n", line);
            strcat(res, tmp);
            flag = 1;
        }
        line++;
    }
    if (flag == 0)
    {
        sprintf(res, "Two source files are same.\n");
    }

    MessageBox(NULL, res, "Result", MB_OK);
    return 0;
}