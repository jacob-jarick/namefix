#!/bin/bash

# linux_install_modules.sh - Install apt packages needed for building Linux executables
sudo apt -y install libperl-dev libx11-dev

echo install cpanminus if not already installed
sudo cpan App::cpanminus

echo Install PAR::Packer for creating executables
sudo cpanm PAR::Packer

echo installing modules for namefix

sudo cpanm Data::Dumper
sudo cpanm MP3::Tag
sudo cpanm File::Spec::Functions
sudo cpanm File::Spec::Functions

sudo cpanm Tk
sudo cpanm Tk::JPEG
sudo cpanm Tk::FontDialog
sudo cpanm Tk::ColourChooser
sudo cpanm Config::IniHash
sudo cpanm MP3::Tag
sudo cpanm Tk::DirTree
sudo cpanm Tk::Balloon
sudo cpanm Tk::NoteBook
sudo cpanm Tk::HList
sudo cpanm Tk::Radiobutton
sudo cpanm Tk::Spinbox
sudo cpanm Tk::Text
sudo cpanm Tk::ROText
sudo cpanm Tk::DynaTabFrame
sudo cpanm Tk::Menu
sudo cpanm Tk::ProgressBar
sudo cpanm Tk::Text::SuperText
sudo cpanm Tk::JComboBox
sudo cpanm Tk::Widget
sudo cpanm Tk::Wm
sudo cpanm Tk::Event
sudo cpanm Time/localtime.pm


