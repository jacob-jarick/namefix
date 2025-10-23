# If you see "running scripts is disabled on this system", run the following in an elevated PowerShell prompt:
#   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
# See: https://go.microsoft.com/fwlink/?LinkID=135170

# NOTE: Data files not bundled - provided by .nsi installer
# NOTE: run from project root directory

# Generate timestamp without spaces by replacing spaces with zeros
$hour = (Get-Date).Hour.ToString("00")
$dtStamp24 = (Get-Date).ToString("yyyyMMdd-HHmmss")

Write-Output "==============================================="
Write-Output "Updating changelog"
Write-Output "."
git log | Select-Object -First 100 | Out-File data\txt\changelog.txt
Write-Output "."

Write-Output "==============================================="
Write-Output "Packaging"
Write-Output "."
Write-Output "SET Build pack date $dtStamp24"
"$dtStamp24" | Out-File .\builds\windows.builddate.txt

Write-Output "."
Write-Output "==============================================="
Write-Output "GUI"
Write-Output "."

Remove-Item namefix-gui.exe -ErrorAction SilentlyContinue
pp --gui -u -o namefix-gui.exe -M Tk -M Tk::JPEG -M Tk::FontDialog -M Tk::ColourChooser -M Config::IniHash -M MP3::Tag -B -M Tk::DirTree -M Tk::Balloon -M Tk::NoteBook -M Tk::HList -M Tk::Radiobutton -M Tk::Spinbox -M Tk::Text -M Tk::ROText -M Tk::DynaTabFrame -M Tk::Menu -M Tk::ProgressBar -M Tk::Text::SuperText -M Tk::JComboBox -M Tk::Widget -M Tk::Wm -M Tk::Event -M Time/localtime.pm -M File::Spec::Functions namefix.pl

Write-Output "."
Write-Output "==============================================="
Write-Output "CLI"
Write-Output "."

Remove-Item namefix.exe -ErrorAction SilentlyContinue
Write-Output "Building namefix.exe..."
pp -u -o namefix.exe -M Time/localtime.pm -M File::Spec::Functions namefix-cli.pl
Write-Output "."

Write-Output "==============================================="
Write-Output "Building GUI PAR"
Write-Output "."

Write-Output "."
Write-Output "==============================================="
Write-Output "Building NSI Installer"
Write-Output "."

if (-not (Test-Path "extra\build installer.nsi")) {
    Write-Output "ERROR: NSI script not found at 'extra\build installer.nsi'"
    Write-Output "Skipping installer build."
} else {
    Write-Output "Building installer from 'extra\build installer.nsi'..."
    & 'C:\Program Files (x86)\NSIS\Bin\makensis.exe' 'extra\build installer.nsi'
    if ($LASTEXITCODE -ne 0) {
        Write-Output "ERROR: NSI installer build failed with error level $LASTEXITCODE"
    } else {
        Write-Output "NSI installer build completed successfully."
    }
}

Write-Output "."
Write-Output "==============================================="
Write-Output "Cleanup"

Remove-Item namefix-gui.exe -ErrorAction SilentlyContinue
Remove-Item namefix.exe -ErrorAction SilentlyContinue
Copy-Item .\namefix-installer.exe .\builds\namefix-installer.exe -Force
Remove-Item .\namefix-installer.exe -ErrorAction SilentlyContinue
