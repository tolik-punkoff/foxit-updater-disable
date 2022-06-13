Unicode true
!include LogicLib.nsh

; Define your application name
!define APPNAME "Foxit Updater Disable Patch"
!define APPNAMEANDVERSION "Foxit Updater Disable Patch"

; Main Install settings
Name "${APPNAMEANDVERSION}"
InstallDir "$PROGRAMFILES\Foxit Software\Foxit Reader\"
OutFile "DisableUpdaterPatch.exe"

DirText "Choose the folder in which to install ${APPNAMEANDVERSION}."
ShowInstDetails show
;RequestExecutionLevel User

Section "Foxit Updater Disable Patch"

	; Set Section properties
	SetOverwrite on
	
	;Check is Foxit reader install in this dir
	IfFileExists "$INSTDIR\FoxitReader.exe" 0 NoReader

	; Unpack Files
	SetOutPath "$TEMP\DUPatch\"
	File "new\simplem.exe"
	File "old\FoxitUpdater.exe"
	
	DetailPrint "Install Dir: $INSTDIR"
	
	Var /GLOBAL Updater1
	Var /GLOBAL Updater2
	StrCpy $Updater1 "$INSTDIR\FoxitUpdater.exe"
	StrCpy $Updater2 "$APPDATA\Foxit Software\Addon\Foxit Reader\FoxitReaderUpdater.exe"
	
	IfFileExists $Updater1 0 NoUpdater
	IfFileExists $Updater2 0 NoUpdater
	
	;Check MD5
	md5dll::GetMD5File "$Updater1"
	Pop $0
	;DetailPrint "$0"
	StrCpy $1 "ba69c0d287a5e3991c2136d2f4002228" ;Patched file MD5
	${If} $0 == $1
		;restore
		MessageBox MB_YESNO|MB_ICONQUESTION "Files patched! Restore originals?"  IDYES 0 IDNO EndProg
		DetailPrint "Restore..."
		CopyFiles "$TEMP\DUPatch\FoxitUpdater.exe" "$Updater1"
		CopyFiles "$TEMP\DUPatch\FoxitUpdater.exe" "$Updater2"
	${Else}
		StrCpy $1 "77b9b7e5296209ab38f3d6d2b5e62117" ;Original file MD5
		${If} $0 == $1
			MessageBox MB_YESNO|MB_ICONQUESTION "Patch files?" IDYES 0 IDNO EndProg
			DetailPrint "Patch..."
			CopyFiles "$TEMP\DUPatch\simplem.exe" "$Updater1"
			CopyFiles "$TEMP\DUPatch\simplem.exe" "$Updater2"
		${Else}
			DetailPrint "Other version..."
			MessageBox MB_YESNO|MB_ICONQUESTION "Unknow version Foxit Reader. Patch files?" IDYES 0 IDNO EndProg
			DetailPrint "Patch..."
			CopyFiles "$TEMP\DUPatch\simplem.exe" "$Updater1"
			CopyFiles "$TEMP\DUPatch\simplem.exe" "$Updater2"
		${EndIf}		
	${EndIf}

	GoTo EndProg
	
	NoUpdater:
		MessageBox MB_YESNO|MB_ICONQUESTION "No updater(s). Maybe updater removed. Install patched updater?" IDYES 0 IDNO EndProg
		DetailPrint "Patch..."
		CopyFiles "$TEMP\DUPatch\simplem.exe" "$Updater1"
		CopyFiles "$TEMP\DUPatch\simplem.exe" "$Updater2"

		GoTo EndProg
	
	NoReader:
		MessageBox MB_ICONSTOP "No file $INSTDIR\FoxitReader.exe. Foxit is not installed or wrong directory selected?"
	EndProg:
SectionEnd

; eof