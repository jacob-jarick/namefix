#!/bin/bash

echo installing modules


sudo perl -MCPAN -e "CPAN::Shell->force(qw(install Tk));"
sudo perl -MCPAN -e "CPAN::Shell->force(qw(install Tk::JComboBox));"
sudo perl -MCPAN -e "CPAN::Shell->force(qw(install Tk::DynaTabFrame));"
sudo perl -MCPAN -e "CPAN::Shell->force(qw(install MP3::Tag));"


