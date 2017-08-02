echo GUI
del namefix-gui.exe
cmd /c pp --gui -o namefix-gui.exe -M Tk -M Time/localtime.pm namefix.pl
echo CLI
del namefix.exe 
cmd /c pp -o namefix.exe  -M Time/localtime.pm namefix-cli.pl
