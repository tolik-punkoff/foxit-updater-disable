Unicode true
!include LogicLib.nsh
!include "FileFunc.nsh"
!insertmacro GetTime

; Main Install settings
Name "Foxit Updater Disable Patch"
InstallDir "$PROGRAMFILES\Foxit Software\Foxit Reader\"
OutFile "DisableUpdaterPatch.exe"

DirText "Choose the folder in which to patch Foxit Updater:"
ShowInstDetails show

!macro PrintProcError ErrCode
	${Switch} ${ErrCode}
		${Case} '0'
			DetailPrint "Success"
		${Break}
		${Case} '601'
			DetailPrint "No permission to terminate process"
		${Break}
		${Case} '602'
			DetailPrint "Not all processes terminated successfully"
		${Break}
		${Case} '603'
			DetailPrint "Process was not currently running"
		${Break}
		${Case} '604'
			DetailPrint "Unable to identify system type"
		${Break}
		${Case} '605'
			DetailPrint "Unsupported OS"
		${Break}
		${Case} '606'
			DetailPrint "Unable to load NTDLL.DLL"
		${Break}
		${Case} '607'
			DetailPrint "Unable to get procedure address from NTDLL.DLL"
		${Break}
		${Case} '608'
			DetailPrint "NtQuerySystemInformation failed"
		${Break}
		${Case} '609'
			DetailPrint "Unable to load KERNEL32.DLL"
		${Break}
		${Case} '610'
			DetailPrint "Unable to get procedure address from KERNEL32.DLL"
		${Break}
		${Case} '611'
			DetailPrint "CreateToolhelp32Snapshot failed"
		${Break}
	${EndSwitch}
!macroend

!macro KillProc Proc
	DetailPrint "Find process ${Proc}..."
	nsProcess::_FindProcess "${Proc}"
	Pop $R0
	!insertmacro PrintProcError $R0
	${If} $R0 = 0
		DetailPrint "Process ${Proc} found. Kill it..."
		nsProcess::_KillProcess "${Proc}"
		!insertmacro PrintProcError $R0
		Sleep 500
	${EndIf}
!macroend

!macro BackupFile
	${GetTime} "" "L" $0 $1 $2 $3 $4 $5 $6
	StrCpy $8 "$2.$1.$0 $4:$5:$6"
	StrCpy $0 "$UPDATER1.$2$1$0$4$5$6.bak"
	DetailPrint "Backup $UPDATER1 --> $0..."
	CopyFiles "$UPDATER1" "$0"
	
	FileOpen $7 "$INSTDIR\manualrestore.txt" w
	FileWrite $7 "Updater changed $8 $\r$\n $\r$\n"
	FileWrite $7 "Manual restore original files: $\r$\n $\r$\n"
	FileWrite $7 "If you wish restore patched files manually, copy: $\r$\n $\r$\n"
	FileWrite $7 "$0 in $UPDATER1 and in $UPDATER2 $\r$\n $\r$\n"
	FileWrite $7 "You may run Foxit Updater Disable Patch for automatic restore."
	FileClose $7
	StrCpy $README "$INSTDIR\manualrestore.txt"
!macroend


Section "Foxit Updater Disable Patch"
	SetOverwrite on
	;set and create variables
	Var /GLOBAL "UPDATER1"
	Var /GLOBAL "UPDATER2"
	Var /GLOBAL "README"
	StrCpy $UPDATER1 "$INSTDIR\FoxitUpdater.exe"
	StrCpy $UPDATER2 "$APPDATA\Foxit Software\Addon\Foxit Reader\FoxitReaderUpdater.exe"
	Var /GLOBAL "PROC0"
	Var /GLOBAL "PROC1"
	Var /GLOBAL "PROC2"
	StrCpy $PROC0 "FoxitReader.exe"
	StrCpy $PROC1 "FoxitUpdater.exe"
	StrCpy $PROC2 "FoxitReaderUpdater.exe"
	Var /GLOBAL "FILEMD5"
	Var /GLOBAL "MD5ORIG"
	Var /GLOBAL "MD5PATCH"
	StrCpy $MD5ORIG "77b9b7e5296209ab38f3d6d2b5e62117"
	StrCpy $MD5PATCH "a8fd17cd2d344ad746c4fe6cb3772a03"
	
	DetailPrint "Find $UPDATER1:"
	;check if file for patching exist
	IfFileExists "$UPDATER1" 0 NoTargetFile
	DetailPrint "File $UPDATER1 found. OK"
	
	;get checksum for target file (UPDATER1)
	md5dll::GetMD5File "$UPDATER1"
	Pop $FILEMD5
	DetailPrint "Target file MD5: $FILEMD5"
	
	;kill processes
	!insertmacro KillProc $PROC0
	!insertmacro KillProc $PROC1
	!insertmacro KillProc $PROC2
	
	;Patch/Restore...
	${If} $FILEMD5 == $MD5ORIG ;Original file. Patch.
		MessageBox MB_YESNO|MB_ICONQUESTION "Patch file?" IDYES 0 IDNO EndProg
		!insertmacro BackupFile
		GetTempFileName $R0
		vpatch::vpatchfile "change.pat" "$UPDATER1" "$R0"
		Pop $R1
		DetailPrint "Patch:"
		DetailPrint "$R1"
		RMDir /r "$APPDATA\Foxit Software\Addon\Foxit Reader\"
		CreateDirectory "$APPDATA\Foxit Software\Addon\Foxit Reader\"
		CopyFiles "$R0" "$UPDATER1"
		IfErrors CopyError 0 ;check copy file error
		CopyFiles "$R0" "$UPDATER2"
		IfErrors CopyError 0 ;check copy file error
		Delete "$R0" ;remove temporary file
	${Else}
		${If} $FILEMD5 == $MD5PATCH ; Patched file. Restore.
			MessageBox MB_YESNO|MB_ICONQUESTION "File patched! Restore original?"  IDYES 0 IDNO EndProg
			!insertmacro BackupFile
			GetTempFileName $R0
			vpatch::vpatchfile "restore.pat" "$UPDATER1" "$R0"
			Pop $R1
			DetailPrint "Restore:"
			DetailPrint "$R1"
			CreateDirectory "$APPDATA\Foxit Software\Addon\Foxit Reader\"
			CopyFiles "$R0" "$UPDATER1"
			IfErrors CopyError 0 ;check copy file error
			CopyFiles "$R0" "$UPDATER2"
			IfErrors CopyError 0 ;check copy file error
			Delete "$R0" ;remove temporary file
		${Else} ;Other checksum, wrong file
			MessageBox MB_ICONSTOP "Unknown or wrong file $UPDATER1. Bad checksum."
			DetailPrint "ERROR: Unknown or wrong file $UPDATER1. Bad checksum. "
			Goto EndProg
		${EndIf}
	${EndIf}

	Goto EndProg

CopyError:
	MessageBox MB_ICONSTOP "Copy error! Target file not changed!"
	Push 666
	Goto EndProg
NoTargetFile:
	DetailPrint "ERROR: File $UPDATER1 NOT FOUND!"
	MessageBox MB_ICONSTOP "No file $UPDATER1. Not installed or wrong directory selected?"
	Push 666
EndProg:
	Pop $R0
	${If} $R0 != 666
		Exec '"notepad.exe" "$README"'
	${EndIf}
SectionEnd