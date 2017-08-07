package bookmark;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;

our $bookmarks;
our %bmhash = ();
my $bookmark_dir = '';

#--------------------------------------------------------------------------------------------------------------
# Bookmark add
#--------------------------------------------------------------------------------------------------------------

sub bm_add
{
	my $name = shift;
	my $dir = shift;

# 	print "\$name = $name\n";

	if($name !~ /\:(\\|\/)$/)
	{
		$name =~ s/(.*)(\\|\/)(.*?$)/$3/;	# set name to directory
	}
	&misc::file_append($config::bookmark_file, "$name\t\t$dir\n");

        &bm_redraw_menu;
}

#--------------------------------------------------------------------------------------------------------------
# bookmark redraw menu
#--------------------------------------------------------------------------------------------------------------

sub bm_redraw_menu
{
	my $n = "";
	my $u = "";
	my $count = 0;

	# delete bookmarks menu (also have to delete help as it comes after bookmarks else menu ordering gets screwed up).

        $bookmarks = $menu::mbar -> cascade
        (
        	-label=>"Bookmarks",
	        -underline=>0,
	        -tearoff=>0,
	);

	# menu command - bookmark cur dir
	$bookmarks -> command
	(
	        -label=>"Bookmark current Directory",
	        -command=> sub { &bm_add($config::dir, $config::dir); }
	);

	# menu command - edit bookmarks
	$bookmarks -> command
	(
	        -label=>"Edit Bookmarks",
	        -command=> sub { &edit_bookmark_list; }
	);

        #create help menu
        # NOTE: this is here, to stop the bookmarks menu switch places upon updating.

	$main::help = $menu::mbar -> cascade
	(
	        -label =>"Help",
	        -underline=>0,
	        -tearoff => 0
	);
	$main::help -> command
	(
	        -label=>'Help',
	        -command=> sub
	        {
	        my $help_text =
"Welcome to the very basic help txt:

DEBUG LEVELS:
0	ERROR
1	warnings & startup messages
2	not used
3	Sub routine called
4	Important but noisy sub details
5	Very noisy sub details
";
			&dialog::show("Help", $help_text);
	        }
	);

        $main::help -> separator();

	$main::help -> command
	(
	        -label=>'About',
	        -command=> sub {&about::show_about; }
	);

	$main::help -> command
	(
	        -label=>"Changelog",
	        -command=> sub  {&dialog::show("Changelog",	join('', &misc::readf($config::changelog))); }
	);

	$main::help -> command
	(
	        -label=>"Todo List",
	        -command=> sub { &dialog::show("Todo",		join('', &misc::readf($config::todo))); }
	);

	$main::help -> command
	(
	        -label=>'Credits/ Thanks',
	        -command=> sub { &dialog::show("Thanks",	join('', &misc::readf($config::thanks))); }
	);

        $main::help -> separator();

	$main::help -> command
	(
	        -label=>"Links",
	        -command=> sub
	        {
			print $_;
			my $links_txt = join("", &misc::readf($config::links));
			&dialog::show("Link", $links_txt);
	        }
	);

	&bm_list_bookmarks;
}

#--------------------------------------------------------------------------------------------------------------
# bookmark list bookmarks
#--------------------------------------------------------------------------------------------------------------

# no hacks on me :D

sub bm_list_bookmarks
{
# 	&misc::plog(3, "sub bm_list_bookmarks:");

	my $n = "";
	my $u = "";
        # add bookmarks, this is where code gets ugly

	$bookmarks -> separator();

	if(!-f $config::bookmark_file)
	{
		# no bookmarks, return
		&misc::plog(0, "bookmarks.pm cant find file $config::bookmark_file");
		return;
	}

	my @tmp_arr = &misc::readf($config::bookmark_file);
	%bmhash = ();

	for my $line(@tmp_arr)
	{
		if($line =~ /^\n/) { next; }
		($n, $u) = split(/\t+/, $line);
		chomp $n;
		chomp $u;

                # if win32 and dir = network path swap \ with /
                # (makes it easier for namefix.pl to work with and perl doesnt mind)
                if($^O eq "MSWin32" && $u =~ /^\\/)
                {
                	$u =~ s/\\/\//g;
                }
                $bookmarks -> checkbutton
		(
			-label=>"$n",
  			-onvalue=>$u,
			-variable=>\$bookmark_dir,
			-command=> sub
			{
				$config::dir = $bookmark_dir;
				print "bookmark.pm: \$config::dir = $config::dir\n";

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
# 	&misc::plog(3, "sub edit_bookmark_list:");
        my $dtext = "";

        if(-f $config::bookmark_file)
        {
                $dtext = &misc::readjf($config::bookmark_file);
        }
        else
        {
                $dtext = "";
        }

        my $top = $main::mw -> Toplevel();
        $top -> title("Edit Bookmark List");

        $top->Label
        (
        	-text=>"Format: <Bookmark Name><TAB><TAB><url>"
        )
        ->grid(-row => 1, -column => 1, -columnspan => 2);

        my $txt = $top -> Scrolled
        (
        	'Text',
                -scrollbars=>"osoe",
        	-font=>$config::dialog_font,
        	-wrap=>'none',
                -width=>80,
                -height=>15
        )
        -> grid
        (
        	-row=>2,
                -column=>1,
                -columnspan=>2
        );
        $txt->menu(undef);

        $txt->insert('end', "$dtext");

        $top -> Button
        (
        	-text=>"Save",
        	-activebackground => 'white',
        	-command => sub
        	{
        		&misc::save_file
        		(
        			"$config::bookmark_file",
        			$txt -> get
        			(
        				'0.0',
        				'end'
        			)
        		);
                        &bm_redraw_menu;
        	}
        )
        -> grid(
        	-row=>4,
        	-column=>1,
        	-sticky=>"ne"
        );

        my $but_close = $top -> Button
        (
        	-text=>"Close",
        	-activebackground=>'white',
        	-command => sub
        	{
        		destroy $top;
        	}
        )
        -> grid
        (
        	-row=>4,
        	-column=>2,
        	-sticky=>"nw"
        );

	$top->resizable(0,0);
}


1;