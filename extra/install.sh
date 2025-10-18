#!/bin/bash

echo install script

sudo chmod a+x ./namefix.pl
sudo rm /usr/bin/namefix.pl
sudo rm /usr/bin/namefix-cli.pl
sudo cp -v ./namefix.pl /usr/bin/
sudo cp -v ./namefix-cli.pl /usr/bin/

