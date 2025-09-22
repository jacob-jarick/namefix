echo GUI
del namefix-gui.exe
cmd /c pp -u --gui -o namefix-gui.exe -M Tk -M Time/localtime.pm namefix.pl
echo CLI
del namefix.exe
cmd /c pp -u -o namefix.exe  -M Time/localtime.pm namefix-cli.pl

echo PAR GUI (for both windows and linux)
del namefix-gui.par 
pp -p -o namefix-gui.par namefix.pl

echo PAR CLI (for both windows and linux)
del namefix.par
pp -p -o namefix.par namefix-cli.pl

echo Done.
