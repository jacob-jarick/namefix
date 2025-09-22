; namefix.pl.nsi

;--------------------------------

Name "Namefix.pl"
OutFile "..\namefix.pl_install.exe"

; The default installation directory
InstallDir $PROGRAMFILES\namefix.pl

; Registry key to check for directory (so if you install again, it will
; overwrite the old one automatically)
InstallDirRegKey HKLM "Software\NSIS_namefix.pl" "Install_Dir"

; Request application privileges for Windows Vista
RequestExecutionLevel admin

!include "EnvVarUpdate.nsh"

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

  ; Put file there
  File /r "..\data"
  File /r "..\extra"
  File /r "..\libs"
  File /r "..\tools"
  File  "..\namefix*.*"
  File  "..\*.pl"
  File  "..\LICENSE"
  File  "..\README.md"


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
  ${EnvVarUpdate} $0 "PATH" "A" "HKLM" "$INSTDIR"
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
  ${un.EnvVarUpdate} $0 "PATH" "R" "HKLM" "$INSTDIR"

SectionEnd
