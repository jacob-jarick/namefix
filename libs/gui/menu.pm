#!/usr/bin/perl

use strict;
use warnings;

#--------------------------------------------------------------------------------------------------------------
# Menu Bar
#--------------------------------------------------------------------------------------------------------------

# Menubar buttons
sub draw_menu 
{
	our $mbar = $main::mw -> Menu();
	$main::mw->configure(-menu=>$main::mbar);

	my $file = $main::mbar -> cascade
	(
	        -label=>'File',
	        -underline=>0,
	        -tearoff => 0
	);

	$file -> command
	(
	        -label =>'Preferences',
	        -underline => 1,
	        -command =>\&edit_prefs
	);

	$file -> command
	(
	        -label =>'Block Rename',
	        -underline => 1,
	        -command =>\&blockrename
	);

	$file -> command
	(
	        -label =>'Undo GUI',
	        -underline => 1,
	        -command =>\&undo_gui
	);

	$file -> command
	(
	        -label =>'Exit',
	        -underline => 1,
	        -command => sub { exit; }
	);

	my $settings = $mbar -> cascade
	(
	        -label=>'Edit Lists',
	        -underline=>0,
	        -tearoff => 0
	);

	$settings -> command
	(
	        -label=>'Specific Casing List',
	        -command=>\&edit_cas_list
	);

	$settings -> command
	(
	        -label=>'Remove Word List',
	        -command=>\&edit_word_list
	);

	$settings -> command
	(
	        -label=>'Remove Pattern List',
	        -command=>\&edit_pat_list
	);

	&bm_redraw_menu;     # creates bookmark menu, still wip

}


1;