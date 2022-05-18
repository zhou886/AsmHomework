#include <windows.h>
#include <string.h>
#include <math.h>
#include <stdio.h>

const double ERR = 1e-18;

HINSTANCE hInst;
HWND hStatic, hBtnOpr[7], hBtnTriFun[3];
HWND hBtnNum[10], hBtnDot, hBtnClc, hBtnDel;
char strStaticBuffer[128], strNum1[32], strNum2[32];
double dNum1, dNum2;
int iOpr, iNum1, iNum2, iNumDot1, iNumDot2;

LRESULT CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM);
int isDigit(char);
int isOperator(char);
int isDot(char);
void Calculate();
void RaiseError(char *);
void Test(int);
void AppendNumberToStatic(int);
void ApeendOperatorToStatic(int);
void AppendDotToNumber();
void TriFuncCal();
void Clear();
void Delete();
double ArrayToNum(char *);
void AppendNumber(char *, char);

int isDigit(char ch)
{
	if (ch >= '0' && ch <= '9')
		return 1;
	else
		return 0;
}

int isDot(char ch)
{
	if (ch == '.')
		return 1;
	else
		return 0;
}

int isOperator(char ch)
{
	if (strchr("+-*/%", ch))
		return 1;
	else
		return 0;
}

void AppendNumber(char *src, char ch)
{
	int len = strlen(src);
	src[len] = ch;
}

double ArrayToNum(char *num)
{
	int i = 0, len = strlen(num);
	double ex = 0, res = 0;
	for (i = 0; i < len; i++)
	{
		if (num[i] == '.')
		{
			ex = 0.1;
		}
		else
		{
			if (ex == 0)
			{
				res = res * 10 + num[i] - '0';
			}
			else
			{
				res = res + (num[i] - '0') * ex;
				ex /= 10;
			}
		}
	}
	return res;
}

void Clear()
{
	memset(strStaticBuffer, 0, sizeof(strStaticBuffer));
	SetWindowText(hStatic, strStaticBuffer);
	iNum1 = iNum2 = iOpr = iNumDot1 = iNumDot2 = 0;
}

void Delete()
{
	GetWindowText(hStatic, strStaticBuffer, 128);
	int len = strlen(strStaticBuffer);
	char ch = strStaticBuffer[len - 1];
	if (isOperator(ch))
	{
		iOpr = 0;
	}
	if (isDot(ch))
	{
		if (iNum2 == 1)
			iNumDot2 = 0;
		else
			iNumDot1 = 0;
	}
	if (isDigit(ch))
	{
		if (isOperator(strStaticBuffer[len - 2]))
			iNum2 = 0;
		if (len == 1)
			iNum1 = 0;
	}
	strStaticBuffer[len - 1] = 0;
	SetWindowText(hStatic, strStaticBuffer);
}

void RaiseError(char *errmsg)
{
	MessageBox(NULL, errmsg, "Error Message", MB_OK);
}

void TriFuncCal(int num)
{
	if (iNum1 == 1 && iOpr == 0)
	{
		iOpr = (num - 38) / 4 + 6;
		Calculate();
	}
	if (iNum1 == 1 && iOpr == 1 && iNum2 == 1)
	{
		Calculate();
		iOpr = (num - 38) / 4 + 6;
		Calculate();
	}
}

void Test(int num)
{
	while (num)
	{
		GetWindowText(hStatic, strStaticBuffer, 128);
		int len = strlen(strStaticBuffer);
		strStaticBuffer[len] = '0' + num % 10;
		SetWindowText(hStatic, strStaticBuffer);
		num /= 10;
	}
}

void AppendDotToNumber()
{
	GetWindowText(hStatic, strStaticBuffer, 128);
	int len = strlen(strStaticBuffer);
	if (iNum1 == 1 && iOpr == 0 && iNumDot1 == 0)
	{
		iNumDot1 = 1;
		strStaticBuffer[len] = '.';
	}
	if (iNum2 == 1 && iNumDot2 == 0)
	{
		iNumDot2 = 1;
		strStaticBuffer[len] = '.';
	}
	SetWindowText(hStatic, strStaticBuffer);
}

void AppendNumberToStatic(int num)
{
	GetWindowText(hStatic, strStaticBuffer, 128);
	int len = strlen(strStaticBuffer);
	if (iNum1 == 0)
	{
		iNum1 = 1;
	}
	else if (iNum2 == 0 && iOpr == 1)
	{
		iNum2 = 1;
	}
	strStaticBuffer[len] = '0' + num;
	SetWindowText(hStatic, strStaticBuffer);
}

void ApeendOperatorToStatic(int opr)
{
	char chOpr[5] = "+-*/%";
	if (iNum1 != 0 && iNum2 == 0 && iOpr == 0)
	{
		iOpr = opr + 1;
		GetWindowText(hStatic, strStaticBuffer, 128);
		int len = strlen(strStaticBuffer);
		strStaticBuffer[len] = chOpr[opr];
		SetWindowText(hStatic, strStaticBuffer);
	}
	if (iNum1 != 0 && iNum2 != 0 && iOpr != 0)
	{
		Calculate();
		iOpr = opr + 1;
		GetWindowText(hStatic, strStaticBuffer, 128);
		int len = strlen(strStaticBuffer);
		strStaticBuffer[len] = chOpr[opr];
		SetWindowText(hStatic, strStaticBuffer);
	}
}

void GetOperand()
{
	memset(strNum1, 0, sizeof(strNum1));
	memset(strNum2, 0, sizeof(strNum2));
	GetWindowText(hStatic, strStaticBuffer, 128);
	int len = strlen(strStaticBuffer);
	int flag = 0;
	for (int i = 0; i < len; i++)
	{
		if ((strStaticBuffer[i] >= '0' && strStaticBuffer[i] <= '9') || strStaticBuffer[i] == '.')
		{
			if (flag == 0)
			{
				int len1 = strlen(strNum1);
				strNum1[len1] = strStaticBuffer[i];
			}
			else
			{
				int len2 = strlen(strNum2);
				strNum2[len2] = strStaticBuffer[i];
			}
		}
		else if (i != 0)
		{
			flag = 1;
		}
	}
	dNum1 = ArrayToNum(strNum1);
	dNum2 = ArrayToNum(strNum2);
	if (strStaticBuffer[0] == '-')
	{
		dNum1 = -dNum1;
	}
}

void Calculate()
{
	GetOperand();
	switch (iOpr)
	{
	case 1: //+
		dNum1 += dNum2;
		break;
	case 2: //-
		dNum1 -= dNum2;
		break;
	case 3: //*
		dNum1 *= dNum2;
		break;
	case 4: ///
		if (dNum2 == 0)
		{
			RaiseError("Dividing Zero!\n");
			return;
		}
		else
		{
			dNum1 /= dNum2;
		}
		break;
	case 5: //%
		if (dNum2 == 0)
		{
			RaiseError("Dividing Zero!\n");
			return;
		}
		else
		{
			dNum1 = fmod(dNum1, dNum2);
		}
		break;
	case 6: // sin
		dNum1 = sin(dNum1);
		break;
	case 7: // cos
		dNum1 = cos(dNum1);
		break;
	case 8: // tan
		dNum1 = tan(dNum1);
		break;
	}
	dNum2 = iNum2 = iOpr = iNumDot2 = 0;
	memset(strStaticBuffer, 0, sizeof(strStaticBuffer));
	if (dNum1 - (int)dNum1 < ERR)
	{
		iNumDot1 = 0;
		sprintf(strStaticBuffer, "%.0f", dNum1);
	}
	else
	{
		iNumDot1 = 1;
		sprintf(strStaticBuffer, "%.5f", dNum1);
	}
	strcpy(strNum1, strStaticBuffer);
	SetWindowText(hStatic, strStaticBuffer);
}

int WINAPI WinMain(
	HINSTANCE hInstance,
	HINSTANCE hPrevInstance,
	PSTR szCmdLine,
	int iCmdShow)
{
	static TCHAR szClassName[] = TEXT("Calculator");
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
		TEXT("Calculator"),
		WS_OVERLAPPEDWINDOW,
		CW_USEDEFAULT,
		CW_USEDEFAULT,
		335,
		420,
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
	HWND hWnd,
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
		hStatic = CreateWindow(
			"static",
			"",
			WS_CHILD | WS_VISIBLE | WS_BORDER | SS_CENTER | SS_CENTERIMAGE,
			15,
			10,
			290,
			50,
			hWnd,
			(HMENU)100,
			hInst,
			NULL);
		char chNum[10] = "0123456789", chShow[4] = {0};
		for (int i = 0; i < 10; i++)
		{
			chShow[0] = chNum[i];
			hBtnNum[i] = CreateWindow(
				"button",
				chShow,
				WS_CHILD | WS_VISIBLE | WS_BORDER | BS_FLAT,
				15 + i % 5 * 60,
				80 + i / 5 * 60,
				50,
				50,
				hWnd,
				(HMENU)i,
				hInst,
				NULL);
		}

		char chOpr[8] = "+-*/%.=";
		for (int i = 0; i < 7; i++)
		{
			chShow[0] = chOpr[i];
			hBtnOpr[i] = CreateWindow(
				"button",
				chShow,
				WS_CHILD | WS_VISIBLE | WS_BORDER | BS_FLAT,
				15 + i % 5 * 60,
				200 + i / 5 * 60,
				50,
				50,
				hWnd,
				(HMENU)10 + i,
				hInst,
				NULL);
		}

		char strTriFun[3][4] = {"sin", "cos", "tan"};
		for (int i = 0; i < 3; i++)
		{
			strcpy(chShow, strTriFun[i]);
			hBtnTriFun[i] = CreateWindow(
				"button",
				chShow,
				WS_CHILD | WS_VISIBLE | WS_BORDER | BS_FLAT,
				135 + i * 60,
				260,
				50,
				50,
				hWnd,
				(HMENU)38 + i,
				hInst,
				NULL);
		}

		hBtnClc = CreateWindow(
			"button",
			"CLC",
			WS_CHILD | WS_VISIBLE | WS_BORDER | BS_FLAT,
			15,
			320,
			140,
			50,
			hWnd,
			(HMENU)50,
			hInst,
			NULL);

		hBtnDel = CreateWindow(
			"button",
			"DEL",
			WS_CHILD | WS_VISIBLE | WS_BORDER | BS_FLAT,
			165,
			320,
			140,
			50,
			hWnd,
			(HMENU)54,
			hInst,
			NULL);
	case WM_PAINT:
		hdc = BeginPaint(hWnd, &ps);
		EndPaint(hWnd, &ps);
		break;
	case WM_DESTROY:
		PostQuitMessage(0);
		break;
	case WM_COMMAND:
		id = LOWORD(wParam);
		if (id >= 0 && id <= 9)
		{
			AppendNumberToStatic(id);
		}
		if (id >= 10 && id <= 26)
		{
			ApeendOperatorToStatic((id - 10) / 4);
		}
		if (id >= 38 && id <= 46)
		{
			TriFuncCal(id);
		}
		if (id == 30)
		{
			AppendDotToNumber();
		}
		if (id == 34)
		{
			Calculate();
		}
		if (id == 50)
		{
			Clear();
		}
		if (id == 54)
		{
			Delete();
		}
		break;
	}
	return DefWindowProc(hWnd, message, wParam, lParam);
}
