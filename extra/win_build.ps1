# If you see "running scripts is disabled on this system", run the following in an elevated PowerShell prompt:
#   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
# See: https://go.microsoft.com/fwlink/?LinkID=135170

# NOTE: Data files directory are not bundled - provided by .nsi installer

# Generate timestamp without spaces by replacing spaces with zeros
$DATETIME = (Get-Date).ToString("yyyyMMdd-HHmmss")
$SHORT_DATE = (Get-Date).ToString("yyMMdd")

# get this scripts directory
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
# get one level up to project root
$PROJECT_ROOT = Split-Path -Parent $SCRIPT_DIR

# get version from perl .\namefix-cli.pl --version
$VERSION = & perl .\namefix-cli.pl --version

$INST_NAME = "namefix.$VERSION-$SHORT_DATE.setup.exe"
$NSI_OUT_PATH = "$PROJECT_ROOT\namefix-installer.exe"
$INSTALLER_BUILD_PATH = "$PROJECT_ROOT\builds\$INST_NAME"
$INSTALLER_SHA1_PATH = "$INSTALLER_BUILD_PATH.sha1sum"

$CHANGELOG_PATH = "$PROJECT_ROOT\data\txt\changelog.txt"

$GUI_EXE = "$PROJECT_ROOT\namefix-gui.exe"
$CLI_EXE = "$PROJECT_ROOT\namefix.exe"

# $BUILD_DATE_FILE = "$INSTALLER_BUILD_PATH.builddate.txt"

Write-Output "==============================================="
Write-Output "Build script"
Write-Output "."
Write-Output "==============================================="
Write-Output "DATETIME:             $DATETIME"
Write-Output "VERSION:              $VERSION"
Write-Output "."
Write-Output "SCRIPT_DIR:           $SCRIPT_DIR"
# Write-Output "BUILD_DATE_FILE:      $BUILD_DATE_FILE"
Write-Output "."
Write-Output "PROJECT_ROOT:         $PROJECT_ROOT"
Write-Output "THIS_SCRIPT_DIR:      $SCRIPT_DIR"
Write-Output "."
Write-Output "INST_NAME:            $INST_NAME"
Write-Output "GUI_EXE:              $GUI_EXE"
Write-Output "CLI_EXE:              $CLI_EXE"
Write-Output "CHANGELOG_PATH:       $CHANGELOG_PATH"
Write-Output "NSI_OUT_PATH:         $NSI_OUT_PATH"
Write-Output "."
Write-Output "INSTALLER_SHA1_PATH:  $INSTALLER_SHA1_PATH"
Write-Output "INSTALLER_BUILD_PATH: $INSTALLER_BUILD_PATH"
Write-Output "INSTALLER_SHA1_PATH:  $INSTALLER_SHA1_PATH"
Write-Output "==============================================="

Write-Output "."
Write-Output "==============================================="
Write-Output "Updating changelog"
Write-Output "."
& git log | Select-Object -First 100 | Out-File $CHANGELOG_PATH

# Write-Output "."
# Write-Output "==============================================="
# Write-Output "SET Build pack date $DATETIME"
# Write-Output "."
# "$DATETIME" | Out-File $BUILD_DATE_FILE

Write-Output "."
Write-Output "==============================================="
Write-Output "GUI"
Write-Output "."

Remove-Item $GUI_EXE -ErrorAction SilentlyContinue
pp --gui -u -o $GUI_EXE -M Tk -M Tk::JPEG -M Tk::FontDialog -M Tk::ColourChooser -M Config::IniHash -M MP3::Tag -B -M Tk::DirTree -M Tk::Balloon -M Tk::NoteBook -M Tk::HList -M Tk::Radiobutton -M Tk::Spinbox -M Tk::Text -M Tk::ROText -M Tk::DynaTabFrame -M Tk::Menu -M Tk::ProgressBar -M Tk::Text::SuperText -M Tk::JComboBox -M Tk::Widget -M Tk::Wm -M Tk::Event -M Time/localtime.pm -M File::Spec::Functions namefix.pl

Write-Output "."
Write-Output "==============================================="
Write-Output "CLI"
Write-Output "."

Remove-Item $CLI_EXE -ErrorAction SilentlyContinue
pp -u -o $CLI_EXE -M Time/localtime.pm -M File::Spec::Functions namefix-cli.pl
Write-Output "."

Write-Output "."
Write-Output "==============================================="
Write-Output "Building NSI Installer"
Write-Output "."

if (-not (Test-Path "extra\build installer.nsi")) {
    Write-Output "ERROR: NSI script not found at 'extra\build installer.nsi'"
    exit 1
} else {
    Write-Output "Building installer from 'extra\build installer.nsi'..."
    & 'C:\Program Files (x86)\NSIS\Bin\makensis.exe' 'extra\build installer.nsi'
    if ($LASTEXITCODE -ne 0) {
        Write-Output "ERROR: NSI installer build failed with error level $LASTEXITCODE"
		exit 1
    } else {
        Write-Output "NSI installer build completed successfully."
    }
}

# copy installer to builds directory
if (Test-Path $NSI_OUT_PATH) {
	Copy-Item $NSI_OUT_PATH $INSTALLER_BUILD_PATH -Force
	Write-Output "Installer copied to '$INSTALLER_BUILD_PATH'"
} else {
	Write-Output "ERROR: Installer not found at '$NSI_OUT_PATH', cannot copy to builds directory."
	exit 1
}

Write-Output "."
Write-Output "==============================================="
Write-Output "Generate sha1sum files"
Write-Output "."

if (Test-Path $NSI_OUT_PATH) {
    $SHA1 = Get-FileHash $NSI_OUT_PATH -Algorithm SHA1
    $SHA1.Hash | Out-File $INSTALLER_SHA1_PATH
    Write-Output "SHA1 '$($SHA1.Hash)' checksum written to '$INSTALLER_SHA1_PATH'"
} else {
    Write-Output "ERROR: Installer not found at '$NSI_OUT_PATH', skipping SHA1 generation."
    exit 1
}

Write-Output "."
Write-Output "==============================================="
Write-Output "Cleanup"

Remove-Item $GUI_EXE -ErrorAction SilentlyContinue
Remove-Item $CLI_EXE -ErrorAction SilentlyContinue
Remove-Item $NSI_OUT_PATH -ErrorAction SilentlyContinue



