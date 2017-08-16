package menu;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;

our $mbar;

#--------------------------------------------------------------------------------------------------------------
# Menu Bar
#--------------------------------------------------------------------------------------------------------------

# Menubar buttons
sub draw
{
	$mbar = $main::mw -> Menu();
	$main::mw->configure(-menu=>$mbar);

	$menu::mbar->delete(0, 4);

	my $file = $mbar -> cascade
	(
	        -label=>'File',
	        -underline=>0,
	        -tearoff => 0
	);

	$file -> command
	(
	        -label =>'Preferences',
	        -underline => 1,
	        -command => sub { &config_dialog::edit_prefs; }
	);
	$file -> command
	(
	        -label =>'Styles',
	        -underline => 1,
	        -command => sub { &style::display; }
	);
	$file -> command
	(
	        -label =>'Block Rename',
	        -underline => 1,
	        -command =>\&blockrename::gui
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
	        -command=>\&edit_lists::cas_list
	);

	$settings -> command
	(
	        -label=>'Remove Word List',
	        -command=>\&edit_lists::word_list
	);

	$settings -> command
	(
	        -label=>'Remove Pattern List',
	        -command=>\&edit_lists::pat_list
	);

 	&bookmark::draw_menu;     # creates bookmark menu, still wip
}


1;
