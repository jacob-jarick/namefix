package blockrename;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;

use Cwd;

#-----------------------------------------------------------------------------------------------------
# blockrename - displays block rename window
#-----------------------------------------------------------------------------------------------------

my $BR_DONE = 0;
my $dir	= '';

my $txt;
my $txt_r;

sub gui
{
	$dir = cwd;

	$BR_DONE = 0;
	&misc::plog(3, "display blockrename gui");

# 	my @tmp = ();

	# create block rename window

        my $br_window = $main::mw -> Toplevel();

        $br_window->title('Block Rename');

	my $balloon = $br_window->Balloon();

	my $txt_frame = $br_window->Frame()
	->pack
	(
		-side => 'top',
		-fill=>'both',
		-expand=>1,
	);
	my $button_frame = $br_window->Frame()
	->pack
	(
		-side => 'bottom',
		-fill=>'both',
	);

	# Text box 1 -  before filenames
	# Editing is allowed in this textbox so you can easily remove 1 file from the list.

        $txt = $txt_frame -> Scrolled
        (
        	'Text',
                -scrollbars=>'osoe',
        	-font=>$config::dialog_font,
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

        $txt_r = $txt_frame -> Scrolled
        (
        	'Text',
                -scrollbars=>	'osoe',
        	-font=>		$config::dialog_font,
		-wrap=>		'none',
        )
        ->grid
	(
		-in=>		$txt_frame,
		-row=>		1,
		-column=>	'2',
		-sticky=>	'nesw',
	);
        $txt_r->menu(undef);

	# weight text boxes in txt_frame (ensures even resive apparently)
	$txt_frame->gridRowconfigure	(1, -weight=>1, -minsize =>50 );
	$txt_frame->gridColumnconfigure	(1, -weight=>1, -minsize =>50 );
	$txt_frame->gridColumnconfigure	(2, -weight=>1, -minsize =>50 );

	my $frm = $button_frame -> Frame()
        -> grid
        (
        	-row=>		4,
        	-column=>	1,
        	-columnspan=>	2,
        	-sticky=>	'ne'
        );

	# Cleanup button

        $frm -> Button
        (
        	-text=>			'Cleanup',
        	-activebackground=>	'white',
        	-command=>		sub { &br_cleanup; }
        )
        -> pack(-side => 'left');

	# Clear button - clears text in right hand box
	# usefull for pasting filenames from clipboard.

        my $clear = $frm -> Button
        (
        	-text=>			'Clear',
        	-activebackground=>	'white',
        	-command=>		sub { $txt_r->delete('0.0','end'); }
        )
        -> pack(-side => 'left');
	$balloon->attach($clear, -msg => "Clears Text In Right hand text box");

	# Filter button - enables use of mainwindows filter
	my $filt = $frm -> Checkbutton
	(
		-text=>		'Filter',
		-variable=>	\$config::hash{FILTER}{value},
		-command=>
		sub
		{
			if($config::hash{FILTER}{value} && $config::filter_string eq '')	# dont enable filter on an empty string
			{
				&misc::plog(1, "sub blockrename: tried to enable filtering with an empty filter");
				$config::hash{FILTER}{value} = 0;
			}
			else
			{
				&txt_reset;
			}

		},
		-activeforeground => 'blue',
	)
        -> pack(-side => 'left');

	# Preview button - displays a window with preview of results

	my $preview = $frm -> Checkbutton
	(
		-text=>			'Preview',
		-variable=>		\$config::PREVIEW,
		-activeforeground=>	'blue'
	)
        -> pack(-side => 'left');
	$balloon->attach($preview, -msg => "Preview changes that will be made.\n\nNote: This option always re-enables after a run for safety.");

        $frm -> Button
        (
        	-text=>			'STOP !',
        	-activebackground=>	'red',
        	-command=>		sub {&config::halt;}
        )
        -> pack(-side => 'left');

	# LIST button

        my $list = $frm -> Button
        (
        	-text=>			'LIST',
        	-activebackground=>	'orange',
        	-command=>		\&txt_reset
        )
        -> pack(-side => 'left');

	$balloon->attach($list, -msg => "List Directory / Reset Text");

	$frm -> Label( -text=>"  " )-> pack(-side => 'left');

	# RUN button

        $frm -> Button
        (
        	-text=>			'RUN',
        	-activebackground=>	'green',
        	-command=>
        	sub
        	{
			if($config::PREVIEW == 0)
			{
				$BR_DONE = 1;
				&br();
				$config::PREVIEW = 1;
			}
			else
			{
				&br_preview::preview();
			}
        	}
        )
        -> pack(-side => 'left');

	$frm -> Label(-text=>"    ")-> pack(-side => 'left');

	# Close button

        $frm -> Button
        (
        	-text=>'Close',
        	-activebackground => 'white',
        	-command => sub
        	{
			if($BR_DONE)
			{
				$BR_DONE = 0;
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
	&run_namefix::prep_globals;
	my @flist	= ();
	my @list	= ();
	my $c		= 0;
	my $file	= '';
	my $dtext	= '';

	@flist	= split(/\n/, $txt -> get('1.0', 'end'));
	@list	= split(/\n/, $txt_r -> get('1.0', 'end'));

	$txt_r->delete('0.0','end');
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
        $txt_r-> insert
        (
        	'end',
        	"$dtext"
        );
}

sub txt_reset
{
	&misc::plog(3, "sub txt_reset");
	&run_namefix::prep_globals;
        my $dtext = join ("\n", &br_readdir($dir));
        &misc::plog(4, "sub txt_reset: dtext: $dtext");

	$txt	->delete('0.0','end');
        $txt	->insert('end', "$dtext");
	$txt_r	->delete('0.0','end');
        $txt_r	->insert('end', "$dtext");
}

sub br
{
	&misc::plog(3, "sub br:");

	if($main::LISTING)
	{
		&misc::plog(0, "sub br: error, a listing is currently being preformed - aborting rename");
		return 0;
	}
	elsif($config::RUN)
	{
		&misc::plog(0, "sub br: error, a rename is currently being preformed - aborting rename");
		return 0;
	}

	$config::STOP 	= 0;
	$config::RUN 	= 1;

	my $result_text	= '';
	my @new_l 	= split(/\n/, $main::txt_r	-> get('1.0', 'end'));
	my @old_l 	= split(/\n/, $main::txt	-> get('1.0', 'end'));
	my @a 		= ();
	my @b 		= ();
	my $of 		= '';	# old file
	my $nf 		= '';	# new file

	# clean arrarys of return chars
	# using chomp caused issues with filenames containing whitespaces at beginging or the end
	# such as "hello.mp3 " or " hello.mp3"
	for my $i(0..$#new_l)
	{
		$new_l[$i] =~ s/\n|\r//g;
	}
	for my $i(0..$#old_l)
	{
		$old_l[$i] =~ s/\n|\r//g;
	}

	&undo::clear;
	&run_namefix::prep_globals;

	&misc::plog(4, "sub br: checking that files to be renamed exist");
	for $of(@old_l)
	{
		&misc::plog(4, "sub br: checking \"$of\"");
		if(!-f $of)
		{
			&misc::plog(0, "sub br: ERROR: old file \"$of\" does not exist");
			$config::RUN = 1;
			return 0;
		}
	}

	if($#old_l != $#new_l)
	{
		&misc::plog(0, "sub br: ERROR: length of new and old list does not match");	# prevent possible user cockup
		$config::RUN = 0;
		return 0;
	}

	for my $c(0 .. $#old_l)	# check for changes - then rename
	{
		if($config::STOP == 1)
		{
			$config::RUN = 0;
			return 0;
		}

		$of = $old_l[$c];
		$nf = $new_l[$c];

		&misc::plog(4, "sub br: processing \"$of\" -> \"$nf\"");

		if(!$nf) # finish when we hit a blank line, else we risk zero'ing the rest of the filenames
		{
			&misc::plog(4, "sub br: no new filename for \"$of\" provided, assuming end of renaming");
			last;
		}

		&misc::plog(4, "sub br: renaming \"$of\" -> \"$nf\"");

		next if $of eq $nf;

		if(&fn_rename ($of, $nf))
		{
			push @config::undo_pre, "$dir/$of";
			push @config::undo_cur, "$dir/$nf";
			push @a, $of;
			push @b, $nf;
			&misc::plog(2, "block rename preformed");
		}
		else
		{
			&misc::plog(0, "block rename failed !");
		}
	}
	&br_show_lists("Block Rename Results", \@a, \@b);
	&txt_reset;

	$config::RUN = 0;
	return 1;
}


sub br_readdir
{
        my @dir_contents = ();
        my @dir_clean = ();

	&misc::plog(3, "br_readdir: '$dir'");

	opendir(DIR, $dir) or &main::quit("sub br_readdir: cant open directory '$dir', $!");
	@dir_contents = CORE::readdir(DIR);
       	closedir DIR;

        for my $file(@dir_contents)
        {
        	next if $file eq '.' || $file eq '..' || $file eq '';

                next if !$config::hash{PROC_DIRS}{value} && -d $file;

                if(!$config::IGNORE_FILE_TYPE == 0 && $file !~ /\.($config::hash{file_ext_2_proc}{value})$/i)
                {
                	next;
                }

		next if $config::hash{FILTER}{value} && !&filter::match($file);

                push @dir_clean, $file;
        }

        return &misc::ci_sort(@dir_clean);
}


1;

