@ECHO off
CLS
REM ===============================================
REM Windows EXE Build Script for namefix.pl
REM Updated with tiered JPEG fallback system:
REM   Tier 1: Tk::JPEG (preferred)
REM   Tier 2: PPM fallback (data/mem.ppm)
REM   Tier 3: Text fallback
REM 
REM NOTE: Data files not bundled - provided by .nsi installer
REM ===============================================

SET dtStamp24=%date:~-4%%date:~7,2%%date:~4,2%_%time:~0,2%%time:~3,2%%time:~6,2%

ECHO ===============================================
ECHO Packaging
ECHO .
ECHO SET Build pack date %dtStamp24%
ECHO %dtStamp24% > builddate.txt

ECHO .
ECHO ===============================================
ECHO GUI
ECHO .

DEL /Q namefix-gui.exe 2>nul
ECHO on
CMD /c pp --gui -u -o namefix-gui.exe -M Tk -M Tk::JPEG -M Tk::FontDialog -M Tk::ColourChooser -M Config::IniHash -M MP3::Tag -B -M Tk::DirTree -M Tk::Balloon -M Tk::NoteBook -M Tk::HList -M Tk::Radiobutton -M Tk::Spinbox -M Tk::Text -M Tk::ROText -M Tk::DynaTabFrame -M Tk::Menu -M Tk::ProgressBar -M Tk::Text::SuperText -M Tk::JComboBox -M Tk::Widget -M Tk::Wm -M Tk::Event -M Time/localtime.pm -M File::Spec::Functions namefix.pl
ECHO off

REM ECHO .
REM ECHO ===============================================
REM ECHO GUI DEBUG
REM ECHO .

DEL /Q namefix-gui-debug.exe 2>nul
REM CMD /c pp -u -o namefix-gui-debug.exe -M Tk -M Tk::JPEG -M Tk::FontDialog -M Tk::ColourChooser -M Config::IniHash -M MP3::Tag -B -M Tk::DirTree -M Tk::Balloon -M Tk::NoteBook -M Tk::HList -M Tk::Radiobutton -M Tk::Spinbox -M Tk::Text -M Tk::ROText -M Tk::DynaTabFrame -M Tk::Menu -M Tk::ProgressBar -M Tk::Text::SuperText -M Tk::JComboBox -M Tk::Widget -M Tk::Wm -M Tk::Event -M Time/localtime.pm -M File::Spec::Functions namefix.pl

ECHO .
ECHO ===============================================
ECHO CLI
ECHO .

DEL /Q namefix.exe 2>nul
ECHO on
CMD /c pp -u -o namefix.exe -M Time/localtime.pm -M File::Spec::Functions namefix-cli.pl
ECHO off

REM ECHO .
REM ECHO ===============================================
REM ECHO JPEG TEST UTILITY 
REM ECHO .

DEL /Q jpgtest.exe 2>nul
REM CMD /c pp -u -o jpgtest.exe -M Tk -M Tk::JPEG -M File::Spec::Functions --bundle jpgtest.pl

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
ECHO .  
ECHO ===============================================
ECHO Done
