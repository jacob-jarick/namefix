# Extra Directory Overview

This folder contains helper scripts and resources for building and packaging the NameFix project.

## Linux Files

- **modules_windows.sh**
  Setup linux build environment.

- **linux_build.sh**  
  Bash script to build and package NameFix for Linux. Generates PAR files, updates changelog, and creates a distributable archive.

- **install.sh**  
  Linux installation script. included in tar archive

## Windows Files

- **win_build.ps1**  
  package GUI & CLI to .exe's and then build installer.

- **build installer.nsi**  
  NSIS script for creating the Windows installer for NameFix.

- **modules_windows.bat**
  Install all CPAN modules for project, needed for build env, not needed for end users using the generated .exe's

- **explorer_namefix_integrate.reg**
  Add right click namefix.pl option to explorer. used by "build installer.nsi" 