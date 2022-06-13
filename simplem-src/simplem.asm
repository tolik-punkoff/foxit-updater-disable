; Simple windows application
; Assembler: MASM32
; Compiling: G:\masm32\bin\ml.exe /c /coff /IG:\masm32\include\ simplem.asm
; Linking: G:\masm32\bin\link.exe simplem.obj  /SUBSYSTEM:WINDOWS /LIBPATH:G:\masm32\lib\

.386
.model flat, stdcall
option casemap:none

include kernel32.inc
includelib kernel32.lib

.data
	szHelp DB 'This program start and end'
	
.code

Start:
	nop
	nop
	nop
	invoke	ExitProcess, 0
end	Start