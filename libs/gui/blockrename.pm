package blockrename;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;

#-----------------------------------------------------------------------------------------------------
# blockrename - displays block rename window
#-----------------------------------------------------------------------------------------------------

sub blockrename
{
	&misc::plog(3, "sub blockrename");

	my @tmp = ();

	# create block rename window

        my $br_window = $main::mw -> Toplevel();
        $br_window -> title
        (
        	"Block Rename"
        );
	my $balloon = $br_window->Balloon();

	my $txt_frame = $br_window->Frame()
	->pack
	(
		-side => 'top',
		-fill=>"both",
		-expand=>1,
	);
	my $button_frame = $br_window->Frame()
	->pack
	(
		-side => 'bottom',
		-fill=>"both",
	);

	# Text box 1
	# this text box is the before filenames
	# Editing is allowed in this textbox so you can easily remove 1 file from the list.

        our $txt = $txt_frame -> Scrolled
        (
        	'Text',
                -scrollbars=>"osoe",
        	-font=>$main::dialog_font,
		-wrap=>'none',
        )
        ->grid
	(
		-in => $txt_frame,
		-row=>1,
		-column => '1',
		-sticky => 'nesw',
	);

        $txt->menu(undef);

	# Text box 2
	# this text box is the after filenames
	# this is where the user usually copy and pastes a list of filenames into.

        our $txt_r = $txt_frame -> Scrolled
        (
        	'Text',
                -scrollbars=>"osoe",
#                -width=>$lw,
#                -height=>$lh,
        	-font=>$main::dialog_font,
		-wrap=>'none',
        )
        ->grid
	(
		-in => $txt_frame,
		-row=>1,
		-column => '2',
		-sticky => 'nesw',
	);
        $txt_r->menu(undef);

	# weight text boxes in txt_frame (ensures even resive apparently)
	$txt_frame->gridRowconfigure(1, -weight=>1, -minsize =>50 );
	$txt_frame->gridColumnconfigure(1, -weight=>1, -minsize =>50 );
	$txt_frame->gridColumnconfigure(2, -weight=>1, -minsize =>50 );

	my $frm = $button_frame -> Frame()
        -> grid
        (
        	-row => 4,
        	-column => 1,
        	-columnspan => 2,
        	-sticky=>"ne"
        );

	# Cleanup button

        $frm -> Button
        (
        	-text=>"Cleanup",
        	-activebackground => 'white',
        	-command => sub
        	{
        		&br_cleanup;
        	}
        )
        -> pack(-side => 'left');

	# Clear button
	# clears text in right hand box
	# usefull for pasting filenames from clipboard.

        my $clear = $frm -> Button
        (
        	-text=>"Clear",
        	-activebackground => 'white',
        	-command => sub
        	{
        		$main::txt_r->delete('0.0','end');
        	}
        )
        -> pack(-side => 'left');
	$balloon->attach
	(
		$clear,
		-msg => "Clears Text In Right hand text box"
	);

	# Filter button
	# enables use of mainwindows filter

	my $filt = $frm -> Checkbutton
	(
		-text=>"Filter",
		-variable=>\$main::FILTER,
		-command=> sub
		{
			if($main::FILTER && $main::filter_string eq "")	# dont enable filter on an empty string
			{
				&misc::plog(1, "sub blockrename: tried to enable filtering with an empty filter");
				$main::FILTER = 0;
			}
			else
			{
				&txt_reset;
			}

		},
		-activeforeground => "blue",
	)
        -> pack(-side => 'left');

	# Preview button
	# displays a window with preview of results

	my $preview = $frm -> Checkbutton
	(
		-text=>"Preview",
		-variable=>\$main::testmode,
		-activeforeground => "blue"
	)
        -> pack(-side => 'left');
	$balloon->attach
	(
		$preview,
		-msg => "Preview changes that will be made.\n\nNote: This option always re-enables after a run for safety."
	);

	# STOP button

        $frm -> Button
        (
        	-text=>"STOP !",
        	-activebackground => 'red',
        	-command => sub
		{
			$main::STOP = 1;
		}
        )
        -> pack(-side => 'left');

	# LIST button

        my $list = $frm -> Button
        (
        	-text=>"LIST",
        	-activebackground => 'orange',
        	-command => \&txt_reset
        )
        -> pack(-side => 'left');

	$balloon->attach
	(
		$list,
		-msg => "List Directory / Reset Text"
	);

	$frm -> Label
	(
		-text=>"  "
	)
	-> pack(-side => 'left');

	# RUN button

        $frm -> Button
        (
        	-text=>"RUN",
        	-activebackground => 'green',
        	-command => sub
        	{
			if($main::testmode == 0)
			{
				$main::BR_DONE = 1;
				&br();
				$main::testmode = 1;
			}
			else
			{
				&br_preview::preview();
			}
        	}
        )
        -> pack(-side => 'left');

	$frm -> Label
	(
		-text=>"    "
	)
	-> pack(-side => 'left');

	# Close button

        $frm -> Button
        (
        	-text=>"Close",
        	-activebackground => 'white',
        	-command => sub
        	{
			if($main::BR_DONE)
			{
				$main::BR_DONE = 0;
        			&dir::ls_dir;
			}
        		destroy $br_window;
        	}
        )
        -> pack(-side => 'left');
	&txt_reset;
}

sub br_cleanup
{
	&misc::plog(3, "sub br_cleanup");
	&prep_globals;
	my @flist = ();
	my @list = ();
	my $c = 0;
	my $file = "";
	my $dtext	= "";

	@flist = split(/\n/, $main::txt -> get('1.0', 'end'));
	@list = split(/\n/, $main::txt_r -> get('1.0', 'end'));

	$main::txt_r->delete('0.0','end');
	for my $new_file(@list)
	{
		$file = $flist[$c];
		$c++;
		if(!$new_file || !$file)	# avoid sending null entrys to subs below
		{
			next;
		}
		&misc::plog(4, "sub br_cleanup: processing \"$file\" -> \"$new_file\"");
		$new_file = &br_txt_cleanup($new_file);				# strip cleanup any crap trailing filename
		$new_file = &fixname::run_fixname_subs($file, $new_file);	# apply fixname routines ($file is needed, else some funcs mangle extensions)
	}

	$dtext = join ("\n", @list);
        $main::txt_r-> insert
        (
        	'end',
        	"$dtext"
        );
}

sub txt_reset
{
	&misc::plog(3, "sub txt_reset");
	&prep_globals;
        my $dtext = join ("\n", &br_readdir($main::dir));
        &misc::plog(4, "sub txt_reset: dtext: $dtext");

	$main::txt->delete('0.0','end');
	$main::txt_r->delete('0.0','end');

        $main::txt-> insert
        (
        	'end',
        	"$dtext"
        );
        $main::txt_r-> insert
        (
        	'end',
        	"$dtext"
        );
}

sub br
{
	&misc::plog(3, "sub br:");

	if($main::LISTING)
	{
		&misc::plog(0, "sub br: error, a listing is currently being preformed - aborting rename");
		return 0;
	}
	elsif($main::RUN)
	{
		&misc::plog(0, "sub br: error, a rename is currently being preformed - aborting rename");
		return 0;
	}

	$main::STOP 	= 0;
	$main::RUN 	= 1;

	my $result_text	= "";
	my @new_l 	= split(/\n/, $main::txt_r -> get('1.0', 'end'));
	my @old_l 	= split(/\n/, $main::txt -> get('1.0', 'end'));
	my @a 		= ();
	my @b 		= ();
	my $c 		= 0;
	my $of 		= "";	# old file
	my $nf 		= "";	# new file

	# clean arrarys of return chars
	# using chomp caused issues with filenames containing whitespaces at beginging or the end
	# such as "hello.mp3 " or " hello.mp3"
	for(@new_l)
	{
		s/\n|\r//g;
	}
	for(@old_l)
	{
		s/\n|\r//g;
	}

	&undo::clear;
	&prep_globals;

	&misc::plog(4, "sub br: checking that files to be renamed exist");
	for $of(@old_l)
	{
		&misc::plog(4, "sub br: checking \"$of\"");
		if(!-f $of)
		{
			&misc::plog(0, "sub br: ERROR: old file \"$of\" does not exist");
			$main::RUN = 1;
			return 0;
		}
	}

	if($#old_l < $#new_l || $#old_l > $#new_l)
	{
		&misc::plog(0, "sub br: ERROR: length of new and old list does not match");	# prevent possible user cockup
		$main::RUN = 0;
		return 0;
	}

	while($c <= $#old_l)	# check for changes - then rename
	{
		if($main::STOP == 1)
		{
			$main::RUN = 0;
			return 0;
		}

		$of = $old_l[$c];
		$nf = $new_l[$c];
		$c++;

		&misc::plog(4, "sub br: processing \"$of\" -> \"$nf\"");

		if(!$nf) # finish when we hit a blank line, else we risk zero'ing the rest of the filenames
		{
			&misc::plog(4, "sub br: no new filename for \"$of\" provided, assuming end of renaming");
			last;
		}


		$nf = &br_ed2k_cleanup($nf);
		&misc::plog(4, "sub br: renaming \"$of\" -> \"$nf\"");

		if($of eq $nf)
		{
			next;
		}

		if(&fn_rename ($of, $nf))
		{
			push @main::undo_pre, $main::cwd."/".$of;
			push @main::undo_cur, $main::cwd."/".$nf;
			push @a, $of;
			push @b, $nf;
			$result_text .= "\"$of\" -> \"$nf\"\n";
			&misc::plog(4, "sub br: renamed");
		}
		else
		{
			&misc::plog(0, "sub br: rename failed !");
		}
	}
	&br_show_lists("Block Rename Results", \@a, \@b);
	&txt_reset;

	$main::RUN = 0;
	return 1;
}


sub br_ed2k_cleanup
{
	my $link = shift;
	&misc::plog(3, "sub br_ed2k_cleanup: \"$link\"");
	if($link =~ m/^ed2k:\/\/\|file\|(.*?)\|/i)
	{
		&misc::plog(4, "sub br_ed2k_cleanup: \"$link\" -> \"$1\"");
		$link = $1;
	}

	return $link;
}
sub br_txt_cleanup
{
	my $link = shift;
	&misc::plog(3, "sub br_txt_cleanup: \"$link\"");
	if($link =~ m/^\s*(.*\.($config::hash{file_ext_2_proc}{value}))\s+/)
	{
		&misc::plog(4, "sub br_txt_cleanup: \"$link\" -> \"$1\"");
		$link = $1;
	}

	return $link;
}


sub br_readdir
{
	my $d = shift;
        my @dl_1 = ();
        my @dl_2 = ();

	&misc::plog(3, "sub br_readdir: \"$d\"");

	opendir(DIR, "$d") or &misc::plog(0, "sub br_readdir: cant open directory $d, $!");
	@dl_1 = CORE::readdir(DIR);
       	closedir DIR;

        for(@dl_1)
        {
        	s/^\s+|\s+$//g;
        	if($_ eq "." || $_ eq ".." || $_ eq "")
        	{
                	next;
                }

                if(!$main::proc_dirs && -d $_)
                {
                	next;
                }

                if(!$main::ig_type == 0 && $_ !~ /\.($config::hash{file_ext_2_proc}{value})$/i)
                {
                	next;
                }

		if($main::FILTER && !&filter::match($_))
		{
			next;
		}

                push @dl_2, $_;
        }

        return &ci_sort(@dl_2);
}


1;

