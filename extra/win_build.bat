@ECHO off
CLS
REM NOTE: Data files not bundled - provided by .nsi installer
REM NOTE: run from project root directory

REM Generate timestamp without spaces by replacing spaces with zeros
SET "hour=%time:~0,2%"
SET "hour=%hour: =0%"
SET dtStamp24=%date:~-4%%date:~7,2%%date:~4,2%_%hour%%time:~3,2%%time:~6,2%

ECHO ===============================================
ECHO Packaging
ECHO .
ECHO SET Build pack date %dtStamp24%
ECHO %dtStamp24% > .\builds\windows.builddate.txt

ECHO .
ECHO ===============================================
ECHO GUI
ECHO .

DEL /Q namefix-gui.exe 2>nul
ECHO on
CMD /c pp --gui -u -o namefix-gui.exe -M Tk -M Tk::JPEG -M Tk::FontDialog -M Tk::ColourChooser -M Config::IniHash -M MP3::Tag -B -M Tk::DirTree -M Tk::Balloon -M Tk::NoteBook -M Tk::HList -M Tk::Radiobutton -M Tk::Spinbox -M Tk::Text -M Tk::ROText -M Tk::DynaTabFrame -M Tk::Menu -M Tk::ProgressBar -M Tk::Text::SuperText -M Tk::JComboBox -M Tk::Widget -M Tk::Wm -M Tk::Event -M Time/localtime.pm -M File::Spec::Functions namefix.pl
ECHO off

ECHO .
ECHO ===============================================
ECHO CLI
ECHO .

DEL /Q namefix.exe 2>nul
ECHO on
CMD /c pp -u -o namefix.exe -M Time/localtime.pm -M File::Spec::Functions namefix-cli.pl
ECHO off

ECHO .
ECHO ===============================================
ECHO Building GUI PAR
ECHO .

DEL /Q namefix-gui.par 2>nul
ECHO Building namefix-gui.par...
ECHO on
CMD /c pp -p -v -o namefix-gui.par namefix.pl
@ECHO off
IF %ERRORLEVEL% NEQ 0 (
    ECHO ERROR: PAR build failed with error level %ERRORLEVEL%
) ELSE (
    ECHO GUI PAR build completed.
)

ECHO .
ECHO ===============================================
ECHO PAR CLI
ECHO .  

DEL /Q namefix-cli.par 2>nul
ECHO Building namefix.par...
ECHO on
CMD /c pp -p -v -o namefix-cli.par namefix-cli.pl
@ECHO off
IF %ERRORLEVEL% NEQ 0 (
    ECHO ERROR: CLI PAR build failed with error level %ERRORLEVEL%
) ELSE (
    ECHO CLI PAR build completed.
)

ECHO .  
ECHO ===============================================
ECHO Building NSI Installer
ECHO .

IF NOT EXIST "extra\build installer.nsi" (
    ECHO ERROR: NSI script not found at "extra\build installer.nsi"
    ECHO Skipping installer build.
) ELSE (
    ECHO Building installer from "extra\build installer.nsi"...
    ECHO on
    "C:\Program Files (x86)\NSIS\Bin\makensis.exe" "extra\build installer.nsi"
    @ECHO off
    IF %ERRORLEVEL% NEQ 0 (
        ECHO ERROR: NSI installer build failed with error level %ERRORLEVEL%
    ) ELSE (
        ECHO NSI installer build completed successfully.
    )
)

ECHO .  
ECHO ===============================================
ECHO Cleanup

DEL /Q namefix-gui.exe 2>nul
DEL /Q namefix.exe 2>nul
COPY /Y .\namefix-installer.exe .\builds\namefix-installer.exe
DEL /Q .\namefix-installer.exe 2>nul