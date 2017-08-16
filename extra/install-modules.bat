echo installing modules

rem  install all Tk modules
cmd /c cpanm -v Tk
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

