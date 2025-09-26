; namefix.pl.nsi

;--------------------------------

Name "Namefix.pl"
OutFile "..\namefix-installer.exe"

; The default installation directory
InstallDir $PROGRAMFILES\namefix.pl

; Registry key to check for directory (so if you install again, it will
; overwrite the old one automatically)
InstallDirRegKey HKLM "Software\NSIS_namefix.pl" "Install_Dir"

; Request application privileges for Windows Vista
RequestExecutionLevel admin

; Function to add to PATH
!define Environ 'HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"'

; Constants for environment update
!define HWND_BROADCAST 0xFFFF
!define WM_WININICHANGE 0x001A

;--------------------------------

; Pages

Page components
Page directory
Page instfiles

UninstPage uninstConfirm
UninstPage instfiles

;--------------------------------

; The stuff to install
Section "namefix.pl (required)"

InitPluginsDir
  SectionIn RO

  ; Set output path to the installation directory.
  SetOutPath $INSTDIR

  ; Dir Includes
  File /r "..\data"
  File /r "..\libs"
  
  ; Explicit file includes
  SetOutPath $INSTDIR\extra
  File  "..\extra\*.reg"
  SetOutPath $INSTDIR
  File  "..\namefix.exe"
  File  "..\namefix-gui.exe"
  File  "..\LICENSE"
  File  "..\README.md"
  File  "..\builddate.txt"
  
  ; Write the installation path into the registry
  WriteRegStr HKLM SOFTWARE\NSIS_namefix.pl "Install_Dir" "$INSTDIR"

  ; Write the uninstall keys for Windows
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\namefix.pl" "DisplayName" "NSIS namefix.pl"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\namefix.pl" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\namefix.pl" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\namefix.pl" "NoRepair" 1
  WriteUninstaller "uninstall.exe"

SectionEnd

Section "Add namefix.pl to explorer right click menu"
  ; add explorer intergration
  WriteRegStr HKEY_CLASSES_ROOT "Directory\shell\namefix" "" "namefix.pl"
  WriteRegStr HKEY_CLASSES_ROOT "Directory\shell\namefix\command" "" "$\"$INSTDIR\namefix-gui.exe$\" $\"%1$\""
SectionEnd

Section "Add namefix.pl to system PATH"
  ; Optionally add install dir to system PATH
  ReadRegStr $0 ${Environ} "PATH"
  StrCmp $0 "" AddToPath_NTContinue
    StrCpy $1 "$0;$INSTDIR"
    Goto AddToPath_NTAddToPath
  AddToPath_NTContinue:
    StrCpy $1 "$INSTDIR"
  AddToPath_NTAddToPath:
    WriteRegExpandStr ${Environ} "PATH" $1
    SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000
SectionEnd

; Optional section (can be disabled by the user)
Section "Start Menu Shortcuts"

  CreateDirectory "$SMPROGRAMS\namefix.pl"
  CreateShortCut "$SMPROGRAMS\namefix.pl\Uninstall.lnk" "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0
  CreateShortCut "$SMPROGRAMS\namefix.pl\namefix.pl.lnk" "$INSTDIR\namefix-gui.exe" "" "$INSTDIR\namefix-gui.exe" 0

SectionEnd

;--------------------------------

; Uninstaller

Section "Uninstall"

  ; Remove registry keys
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\namefix.pl"
  DeleteRegKey HKLM SOFTWARE\NSIS_namefix.pl
  DeleteRegKey HKEY_CLASSES_ROOT "Directory\shell\namefix"

  ; Remove files and uninstaller
  Delete $INSTDIR\namefix.exe
  Delete $INSTDIR\namefix-gui.exe
  Delete $INSTDIR\uninstall.exe

  ; Remove shortcuts, if any
  Delete "$SMPROGRAMS\namefix.pl\*.*"

  ; Remove directories used
  RMDir "$SMPROGRAMS\namefix.pl"
  RMDir "$INSTDIR"

  ; remove from system PATH if added
  ReadRegStr $0 ${Environ} "PATH"
  StrCpy $1 $0 1 -1 ; copy last char
  StrCmp $1 ";" +2 ; if last char != ;
    StrCpy $0 "$0;" ; append ;
  Push $0
  Push "$INSTDIR;"
  Call un.StrStr ; Find `$INSTDIR;` in $0
  Pop $2 ; pos of our dir
  StrCmp $2 "" unRemoveFromPath_done
    ; else, it is in path
    StrLen $3 "$INSTDIR;"
    StrLen $4 $2
    StrCpy $5 $0 $2 ; $5 is now the part before the path to remove
    IntOp $2 $2 + $3 ; $2 is now the pos after the path to remove
    IntOp $4 $4 - $3 ; $4 is now the part after the path to remove
    StrCpy $6 $2 $4
    StrCpy $3 "$5$6"
    StrCpy $5 $3 1 -1 ; copy last char
    StrCmp $5 ";" 0 +2 ; if last char == ;
      StrCpy $3 $3 -1 ; remove last char
    WriteRegExpandStr ${Environ} "PATH" $3
    SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000
  unRemoveFromPath_done:

SectionEnd

; Helper function for string search
Function un.StrStr
  Exch $R1 ; st=haystack,old$R1, $R1=needle
  Exch    ; st=old$R1,haystack, $R1=needle
  Exch $R2 ; st=old$R1,old$R2, $R2=haystack, $R1=needle
  Push $R3
  Push $R4
  Push $R5
  StrLen $R3 $R1
  StrCpy $R4 0
  ; $R1=needle
  ; $R2=haystack
  ; $R3=len(needle)
  ; $R4=cnt
  ; $R5=tmp
  loop:
    StrCpy $R5 $R2 $R3 $R4
    StrCmp $R5 $R1 done
    StrCmp $R5 "" done
    IntOp $R4 $R4 + 1
    Goto loop
  done:
  StrCpy $R1 $R2 "" $R4
  Pop $R5
  Pop $R4
  Pop $R3
  Pop $R2
  Exch $R1
FunctionEnd
