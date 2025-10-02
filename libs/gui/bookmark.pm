package bookmark;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;

use Cwd;

our $bookmarks;
our %bmhash 		= ();
my $bookmark_dir 	= '';

#--------------------------------------------------------------------------------------------------------------
# Bookmark add
#--------------------------------------------------------------------------------------------------------------

sub bm_add
{
	my $name	= shift;
	my $dir		= shift;

	if($name !~ /\:(\\|\/)$/)
	{
		$name =~ s/(.*)(\\|\/)(.*?$)/$3/;	# set name to directory
	}

	&misc::file_append($globals::bookmark_file, "$name\t\t$dir\n");
	&menu::draw;
}

#--------------------------------------------------------------------------------------------------------------
# bookmark redraw menu
#--------------------------------------------------------------------------------------------------------------

sub draw_menu
{
	my $n		= '';
	my $u		= '';
	my $count	= 0;

	$bookmarks = $menu::mbar-> cascade
	(
		-label=>		'Bookmarks',
		-underline=>	0,
		-tearoff=>		0,
	);

	# menu command - bookmark cur dir
	$bookmarks -> command
	(
		-label=>	"Bookmark current Directory",
		-command=>	sub { &bm_add($globals::dir, $globals::dir); }
	);

	# menu command - edit bookmarks
	$bookmarks -> command
	(
		-label=>	'Edit Bookmarks',
		-command=>	sub { &edit_bookmark_list; }
	);

        #create help menu
        # NOTE: this is here, to stop the bookmarks menu switch places upon updating.

	$main::help = $menu::mbar -> cascade
	(
		-label=>		'Help',
		-underline=>	0,
		-tearoff=>		0
	);
	$main::help -> command
	(
		-label=>	'Help',
		-command=>	sub { &dialog::show('Help', "Help system available via F1 key or command line --help options.\n\nSee README.md for detailed documentation."); }
	);

	$main::help -> separator();

	$main::help -> command
	(
		-label=>	'About',
		-command=> 	sub { &about::show_about; }
	);

	$main::help -> command
	(
		-label=>	'Changelog',
		-command=> 	sub {&dialog::show('Changelog',	join('', &misc::readf($globals::changelog))); }
	);

	$main::help -> command
	(
		-label=>	'Todo List',
		-command=> 	sub { &dialog::show('Todo',		join('', &misc::readf($globals::todo))); }
	);

	$main::help -> command
	(
		-label=>	'Credits/ Thanks',
		-command=> 	sub { &dialog::show('Thanks',	join('', &misc::readf($globals::thanks))); }
	);

	$main::help -> separator();

	$main::help -> command
	(
		-label=>	'Links',
		-command=> 	
		sub
		{
			my $links_txt = join('', &misc::readf($globals::links));
			&dialog::show('Link', $links_txt);
		}
	);

	&list_bookmarks;
}

#--------------------------------------------------------------------------------------------------------------
# bookmark list bookmarks
#--------------------------------------------------------------------------------------------------------------

# no hacks on me :D

sub list_bookmarks
{
	my $bname = '';
	my $bpath = '';

	%bmhash = ();

	$bookmarks->separator();

	if(!-f $globals::bookmark_file)
	{
		&misc::plog(2, "bookmark::bm_list_bookmarks bookmarks file not found, creating emptyfile $globals::bookmark_file");
		&misc::null_file($globals::bookmark_file);
		return;
	}

	for my $line(&misc::readf($globals::bookmark_file))
	{
		$line =~ s/\t+/\t/g;

		if($line =~ /^\s*\n/) { next; }
		next if $line !~ /^(.+?)\t+(.+?)$/;
		($bname, $bpath) = ($1, $2);

		# path swap \ with /
		$bpath =~ s/\\/\//g if $bpath =~ /\\/;

		$bookmarks->checkbutton
		(
			-label=>	$bname,
  			-onvalue=>	$bpath,
  			-offvalue=>	$bpath,
			-variable=>	\$bookmark_dir,
			-command=> 
			sub
			{
				chdir $bookmark_dir;
				$globals::dir = cwd;

				&misc::plog(3, "bookmark: cd '$globals::dir'");

				&dir::ls_dir;
			}
		);
	}
	return 1;
}

#--------------------------------------------------------------------------------------------------------------
# Edit Bookmarks.
#--------------------------------------------------------------------------------------------------------------

sub edit_bookmark_list
{
	my $dtext =	&misc::readjf($globals::bookmark_file) if(-f $globals::bookmark_file);

	my $top = $main::mw->Toplevel();
	$top->title("Edit Bookmark List");

	$top->
		Label(-text=>'Format: <Bookmark Name><TAB><TAB><url>')
		->grid(-row => 1, -column => 1, -columnspan => 2);

	my $txt = $top -> Scrolled
	(
		'Text',
		-scrollbars=>	'osoe',
		-font=>			$config::dialog_font,
		-wrap=>			'none',
		-width=>		80,
		-height=>		15
	)
	-> grid
	(
		-row=>			2,
		-column=>		1,
		-columnspan=>	2
	);
	$txt->menu(undef);

	$txt->insert('end', $dtext);

	$top -> Button
	(
		-text=>					'Save',
		-activebackground=> 	'white',
		-command => 			
		sub
		{
			&misc::save_file($globals::bookmark_file, $txt -> get('0.0', 'end') );
			&menu::draw;
		}
	)
	-> grid
	(
		-row=>		4,
		-column=>	1,
		-sticky=>	'ne'
	);

	my $but_close = $top -> Button
	(
		-text=>				'Close',
		-activebackground=>	'white',
		-command => 		sub { destroy $top; }
	)
	-> grid
	(
		-row=>		4,
		-column=>	2,
		-sticky=>	'nw'
	);

	$top->resizable(0,0);
}

1;
