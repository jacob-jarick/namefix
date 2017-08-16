package bookmark;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;

use Cwd;

our $bookmarks;
our %bmhash = ();
my $bookmark_dir = '';

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
	&misc::file_append($config::bookmark_file, "$name\t\t$dir\n");

        &menu::draw;
}

#--------------------------------------------------------------------------------------------------------------
# bookmark redraw menu
#--------------------------------------------------------------------------------------------------------------

sub draw_menu
{
	my $n = '';
	my $u = '';
	my $count = 0;

        $bookmarks = $menu::mbar -> cascade
        (
        	-label=>	'Bookmarks',
	        -underline=>	0,
	        -tearoff=>	0,
	);

	# menu command - bookmark cur dir
	$bookmarks -> command
	(
	        -label=>	"Bookmark current Directory",
	        -command=>	sub { &bm_add($config::dir, $config::dir); }
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
	        -label=>	'Help',
	        -underline=>	0,
	        -tearoff=>	0
	);
	$main::help -> command
	(
		-label=>'Help',
		-command=> sub { &dialog::show('Help', "TODO: create help.txt"); }
	);

	$main::help -> separator();

	$main::help -> command
	(
	        -label=>'About',
	        -command=> sub { &about::show_about; }
	);

	$main::help -> command
	(
	        -label=>'Changelog',
	        -command=> sub  {&dialog::show('Changelog',	join('', &misc::readf($config::changelog))); }
	);

	$main::help -> command
	(
	        -label=>'Todo List',
	        -command=> sub { &dialog::show('Todo',		join('', &misc::readf($config::todo))); }
	);

	$main::help -> command
	(
	        -label=>'Credits/ Thanks',
	        -command=> sub { &dialog::show('Thanks',	join('', &misc::readf($config::thanks))); }
	);

	$main::help -> separator();

	$main::help -> command
	(
		-label=>'Links',
		-command=> sub
	        {
			my $links_txt = join('', &misc::readf($config::links));
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
	my $n = '';
	my $u = '';

	$bookmarks -> separator();

	if(!-f $config::bookmark_file)
	{
		&misc::plog(0, "bookmark::bm_list_bookmarks cant find file $config::bookmark_file");
		return;
	}

	%bmhash = ();

	for my $line(&misc::readf($config::bookmark_file))
	{
		$line =~ s/\t+/\t/g;

		if($line =~ /^\s*\n/) { next; }
		next if $line !~ /^(.+?)\t+(.+?)$/;
		($n, $u) = ($1, $2);

                # path swap \ with /
                $u =~ s/\\/\//g if $u =~ /\\/;

                $bookmarks -> checkbutton
		(
			-label		=> $n,
  			-onvalue	=> $u,
  			-offvalue	=> $u,
			-variable	=> \$bookmark_dir,
			-command	=> sub
			{
				chdir $bookmark_dir;
				$config::dir = cwd;

				&misc::plog(3, "bookmark: cd '$config::dir'");

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
        my $dtext = '';
	$dtext = &misc::readjf($config::bookmark_file) if(-f $config::bookmark_file);

	my $top = $main::mw -> Toplevel();
	$top -> title("Edit Bookmark List");

	$top->Label(-text=>'Format: <Bookmark Name><TAB><TAB><url>')
	->grid(-row => 1, -column => 1, -columnspan => 2);

        my $txt = $top -> Scrolled
        (
        	'Text',
                -scrollbars=>	'osoe',
        	-font=>		$config::dialog_font,
        	-wrap=>		'none',
                -width=>	80,
                -height=>	15
        )
        -> grid
        (
        	-row=>		2,
                -column=>	1,
                -columnspan=>	2
        );
        $txt->menu(undef);

        $txt->insert('end', $dtext);

        $top -> Button
        (
        	-text=>'Save',
        	-activebackground => 'white',
        	-command => sub
        	{
        		&misc::save_file($config::bookmark_file, $txt -> get('0.0', 'end') );
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
        	-text=>'Close',
        	-activebackground=>'white',
        	-command => sub { destroy $top; }
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
