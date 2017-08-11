#!/bin/bash

echo install script

sudo chmod a+x ./namefix.pl
sudo rm /usr/bin/namefix.pl
sudo rm /usr/bin/namefix-cli.pl
sudo ln -s `pwd`/namefix.pl /usr/bin/namefix.pl
sudo ln -s `pwd`/namefix-cli.pl /usr/bin/namefix-cli.pl

