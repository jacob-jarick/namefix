package menu_help;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;

sub draw_menu
{
	$main::help = $menu::mbar->cascade
	(
		-label=>		'Help',
		-underline=>	0,
		-tearoff=>		0
	);

	$main::help->command
	(
		-label=>	'Help',
		-command=>	sub { &dialog::show('Help', "Help system available via F1 key or command line --help options.\n\nSee README.md for detailed documentation."); }
	);

	$main::help->command
	(
		-label=>	'View States',
		-command=>	
		sub 
		{ 
			&misc::plog
			(
				2, 
				"States\n".
				"\tlist:\t\t "	. &state::get('list')	."\n".
				"\trun:\t\t "	. &state::get('run')	."\n".
				"\tstop:\t\t "	. &state::get('stop')	."\n".
				"\tidle:\t\t "	. &state::get('idle')	."\n"
			);
		}
	);

	$main::help->command
	(
		-label=>	'Error Log Test',
		-command=>	
		sub 
		{ 
			&misc::plog(0, "This is a test error log message.");
		}
	);

	$main::help->separator();

	$main::help->command
	(
		-label=>	'About',
		-command=> 	sub { &about::show_about; }
	);

	$main::help->command
	(
		-label=>	'Changelog',
		-command=> 	sub {&dialog::show('Changelog',	join('', &misc::readf($globals::changelog))); }
	);

	$main::help->command
	(
		-label=>	'Todo List',
		-command=> 	sub { &dialog::show('Todo',		join('', &misc::readf($globals::todo))); }
	);

	$main::help->command
	(
		-label=>	'Credits/ Thanks',
		-command=> 	sub { &dialog::show('Thanks',	join('', &misc::readf($globals::thanks))); }
	);

	$main::help->separator();

	$main::help->command
	(
		-label=>	'Links',
		-command=> 	
		sub
		{
			my $links_txt = join('', &misc::readf($globals::links));
			&dialog::show('Link', $links_txt);
		}
	);
}

1;