echo installing modules

rem cpan update
cmd /c cpan -u

rem install cpanminus if not already installed
cmd /c cpan App::cpanminus
rem Install PAR::Packer for creating executables 
cmd /c cpanm --notest PAR::Packer

rem  install all Tk modules
@REM cmd /c cpanm -v Tk

rem  install patched Tk module to avoid build issues
rem https://github.com/StrawberryPerl/Perl-Dist-Strawberry/issues/87#issuecomment-2292839449
rem known issues with building Tk on Strawberry Perl 5.32 and later
rem https://github.com/eserte/perl-tk/issues/87
rem alternative solution is to install an older Strawberry Perl version (strawberry-perl-5.14.4.1-64bit.msi works)
cmd /c cpanm --force --notest https://github.com/StrawberryPerl/Perl-Dist-Strawberry/releases/download/patched_cpan_modules/Tk-804.036_001.tar.gz

cmd /c cpanm -v Tk::Menu
cmd /c cpanm -v Tk::DynaTabFrame
cmd /c cpanm -v Tk::NoteBook

cmd /c cpanm -v Tk::Radiobutton
cmd /c cpanm -v Tk::Spinbox
cmd /c cpanm -v Tk::JComboBox
cmd /c cpanm -v Tk::HList
cmd /c cpanm -v Tk::DirTree

cmd /c cpanm -v Tk::JPEG
cmd /c cpanm -v Tk::Balloon
cmd /c cpanm -v Tk::ProgressBar
cmd /c cpanm -v Tk::ColourChooser

cmd /c cpanm -v Tk::Text
cmd /c cpanm -v Tk::ROText
cmd /c cpanm -v Tk::Text::SuperText

cmd /c cpanm -v Tk::FontDialog


cmd /c cpanm -v --force use Config::IniHash

rem  file tag modules
cmd /c cpanm -v MP3::Tag

rem  file modules
cmd /c cpanm -v File::Find
cmd /c cpanm -v File::Basename
cmd /c cpanm -v File::Copy

rem  time
cmd /c cpanm -v Time::localtime

rem  debugging
cmd /c cpanm -v Data::Dumper::Concise
cmd /c cpanm -v Carp

rem Image::ExifTool for metadata reading/writing
cmd /c cpanm -v Image::ExifTool



