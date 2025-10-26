#!/bin/bash

echo installing apt packages

sudo apt update
sudo apt -y install libperl-dev libx11-dev tree
sudo apt -y install build-essential libpng-dev zlib1g-dev libx11-dev libxt-dev tcl-dev tk-dev

echo cpan
sudo cpan -u
sudo cpan App::cpanminus
sudo cpanm CPAN::DistnameInfo
sudo cpanm PAR::Packer
sudo cpanm Log::Log4perl

echo debugging modules

sudo cpanm Data::Dumper
sudo cpanm Data::Dumper::Concise
sudo cpanm Carp

echo file tag modules

sudo cpanm MP3::Tag
sudo cpanm -v Image::ExifTool

echo file system modules

sudo cpanm File::Spec::Functions
sudo cpanm File::Find
sudo cpanm File::Basename
sudo cpanm File::Copy

echo Tk modules

sudo cpanm -v --force Tk

sudo cpanm Tk::Balloon
sudo cpanm Tk::ColourChooser
sudo cpanm Tk::DirTree
sudo cpanm Tk::DynaTabFrame
sudo cpanm Tk::Event
sudo cpanm Tk::FontDialog
sudo cpanm Tk::HList
sudo cpanm Tk::JComboBox
sudo cpanm Tk::JPEG
sudo cpanm Tk::Menu
sudo cpanm Tk::NoteBook
sudo cpanm Tk::ProgressBar
sudo cpanm Tk::Radiobutton
sudo cpanm Tk::ROText
sudo cpanm Tk::Spinbox
sudo cpanm Tk::Text
sudo cpanm Tk::Text::SuperText
sudo cpanm Tk::Widget
sudo cpanm Tk::Wm

echo misc modules
sudo cpanm Config::IniHash
sudo cpanm Time/localtime.pm


