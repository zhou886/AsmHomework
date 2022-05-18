.386
.model flat, stdcall
option casemap:none
includelib  msvcrt.lib
includelib  string.h
includelib  math.h
includelib  stdio.h
includelib  windows.h

strlen      PROTO C :ptr sbyte
strchr      PROTO C :ptr sbyte, :sbyte
strcpy      PROTO C :ptr sbyte, :ptr sbyte
memset      PROTO C :ptr sbyte, :dword, :dword
