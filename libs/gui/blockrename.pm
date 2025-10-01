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

my $list_box;
my $rename_box;

# create block rename window
sub gui
{
	$dir		= cwd;
	$BR_DONE	= 0;
	my $br_window	= $main::mw -> Toplevel();
	my $balloon	= $br_window->Balloon();

	&misc::plog(3, "display blockrename gui");

	$br_window->title('Block Rename');

	my $txt_frame = $br_window->Frame()
	->pack
	(
		-side=>		'top',
		-fill=>		'both',
		-expand=>	1,
	);
	my $button_frame = $br_window->Frame()
	->pack
	(
		-side=>	'bottom',
		-fill=>	'both',
	);

	# Text box 1 -  before filenames
	# Editing is allowed in this textbox so you can easily remove 1 file from the list.

	$list_box = $txt_frame -> Scrolled
	(
		'Text',
		-scrollbars=>	'osoe',
		-font=>			$config::dialog_font,
		-wrap=>			'none',
	)	
	->grid
	(
		-in=>		$txt_frame,
		-row=>		1,
		-column=>	1,
		-sticky=>	'nesw',
	);

	$list_box->menu(undef);

	# Text box 2
	# this text box is the after filenames
	# this is where the user usually copy and pastes a list of filenames into.

	$rename_box = $txt_frame -> Scrolled
	(
		'Text',
		-scrollbars=>	'osoe',
		-font=>			$config::dialog_font,
		-wrap=>			'none',
	)
	->grid
	(
		-in=>		$txt_frame,
		-row=>		1,
		-column=>	2,
		-sticky=>	'nesw',
	);
        $rename_box->menu(undef);

	# weight text boxes in txt_frame (ensures even resive apparently)
	$txt_frame->gridRowconfigure	(1, -weight=>1, -minsize =>50 );
	$txt_frame->gridColumnconfigure	(1, -weight=>1, -minsize =>50 );
	$txt_frame->gridColumnconfigure	(2, -weight=>1, -minsize =>50 );

	my $button_sub_frame = $button_frame -> Frame()
	-> grid
	(
		-row=>			4,
		-column=>		1,
		-columnspan=>	2,
		-sticky=>		'ne'
	);

	# Cleanup button

	$button_sub_frame -> Button
	(
		-text=>				'Cleanup',
		-activebackground=>	'white',
		-command=>			sub { &br_cleanup; }
	)
	-> pack(-side=>'left');

	# Clear button - clears text in right hand box
	# useful for pasting filenames from clipboard.

	my $clear = $button_sub_frame->Button
	(
		-text=>				'Clear',
		-activebackground=>	'white',
		-command=>			sub { $rename_box->delete('0.0','end'); }
	)
	->pack(-side=>'left');

	$balloon->attach($clear, -msg => "Clears Text In Right hand text box");

	# Filter button - enables use of mainwindows filter
	my $filt = $button_sub_frame->Checkbutton
	(
		-text=>		'Filter',
		-variable=>	\$config::hash{filter}{value},
		-command=>
		sub
		{
			if($config::hash{filter}{value} && $config::filter_string eq '')	# don't enable filter on an empty string
			{
				&misc::plog(1, "sub blockrename: tried to enable filtering with an empty filter");
				$config::hash{filter}{value} = 0;
			}
			else
			{
				&txt_reset;
			}

		},
		-activeforeground=>'blue',
	)
	->pack(-side=>'left');

	# Preview button - displays a window with preview of results

	my $preview = $button_sub_frame->Checkbutton
	(
		-text=>			'Preview',
		-variable=>		\$config::PREVIEW,
		-activeforeground=>	'blue'
	)
	->pack(-side => 'left');

	$balloon->attach($preview, -msg => "Preview changes that will be made.\n\nNote: This option always re-enables after a run for safety.");

	$button_sub_frame->Button
	(
		-text=>				'STOP !',
		-activebackground=>	'red',
		-command=>			sub {&config::halt;}
	)
	->pack(-side => 'left');

	# LIST button

	my $list = $button_sub_frame->Button
	(
		-text=>				'LIST',
		-activebackground=>	'orange',
		-command=>			\&txt_reset
	)
	-> pack(-side => 'left');

	$balloon->attach($list, -msg => "List Directory / Reset Text");

	$button_sub_frame->Label(-text=>'  ')->pack(-side => 'left');

	# RUN button

	$button_sub_frame->Button
	(
		-text=>				'RUN',
		-activebackground=>	'green',
		-command=>
		sub
		{
			if(!$config::PREVIEW)
			{
				$BR_DONE = 1;
				&br();
				$config::PREVIEW = 1;
			}
			else
			{
				my @list1 = split(/\n/, $list_box->	get('1.0', 'end'));
				my @list2 = split(/\n/, $rename_box->	get('1.0', 'end'));

				&br_preview::preview(\@list1, \@list2);
			}
		}
	)
	-> pack(-side => 'left');

	$button_sub_frame->Label(-text=>'    ')-> pack(-side=>'left');

	# Close button

	$button_sub_frame -> Button
	(
		-text=>			'Close',
		-activebackground=>	'white',
		-command=>
		sub
		{
			if($BR_DONE)
			{
				$BR_DONE = 0;
				&dir::ls_dir;
			}
			destroy $br_window;
		}
	)
	->pack(-side=>'left');
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

	@flist	= split(/\n/, $list_box->	get('1.0', 'end'));
	@list	= split(/\n/, $rename_box->	get('1.0', 'end'));

	$rename_box->delete('0.0','end');
	for my $new_file(@list)
	{
		$file = $flist[$c];
		$c++;
		next if $new_file eq '' || $file eq '';	# avoid blanks

		$new_file = &txt_cleanup($new_file);						# strip cleanup any crap trailing filename
		$new_file = &fixname::run_fixname_subs($file, $new_file);	# apply fixname routines ($file is needed, else some funcs mangle extensions)
		&misc::plog(4, "br_cleanup: '$file' -> '$new_file'") if $file ne $new_file;
	}

	$dtext = join ("\n", @list);
	$rename_box->insert('end', $dtext);
}

sub txt_cleanup
{
	my $text = shift;
	$text =~ s/^\s+//;
	$text =~ s/\s+$//;

	return $text;
}

sub txt_reset
{
	&misc::plog(3, "sub txt_reset");
	&run_namefix::prep_globals;
	my $dtext = join ("\n", &br_readdir($dir));
	&misc::plog(4, "sub txt_reset: dtext: $dtext");

	$list_box->		delete('0.0','end');
	$rename_box->	delete('0.0','end');
	$list_box->		insert('end', "$dtext");
	$rename_box->	insert('end', "$dtext");
}

sub br
{
	&misc::plog(3, "sub br:");

	if($main::LISTING)
	{
		&misc::plog(0, "sub br: error, a listing is currently being performed - aborting rename");
		return 0;
	}
	elsif($config::RUN)
	{
		&misc::plog(0, "sub br: error, a rename is currently being performed - aborting rename");
		return 0;
	}

	$config::STOP 	= 0;
	$config::RUN 	= 1;

	my $result_text	= '';
	my @new_l 		= split(/\n/, $rename_box->	get('1.0', 'end'));
	my @old_l 		= split(/\n/, $list_box->	get('1.0', 'end'));
	my @new_a 		= ();
	my @new_b 		= ();

	# clean arrarys of return chars
	# using chomp caused issues with filenames containing whitespaces at beginging or the end
	# such as "hello.mp3 " or " hello.mp3"
	for my $i(0..$#new_l)
	{
		$new_l[$i] =~ s/\n|\r//g;
		$old_l[$i] =~ s/\n|\r//g;
	}

	&undo::clear;
	&run_namefix::prep_globals;

	&misc::plog(4, "sub br: checking that files to be renamed exist");
	for my $file_old(@old_l)
	{
		&misc::plog(4, "sub br: checking '$file_old'");
		if(!-f $file_old)
		{
			&misc::plog(0, "sub br: ERROR: old file '$file_old' does not exist");
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
		if($config::STOP)
		{
			$config::RUN = 0;
			return 0;
		}

		my $file_old = $old_l[$c];
		my $file_new = $new_l[$c];

		&misc::plog(4, "sub br: processing '$file_old' -> '$file_new'");

		if($file_new eq '') # finish when we hit a blank line, else we risk zero'ing the rest of the filenames
		{
			&misc::plog(4, "br: \$file_new eq '', assuming end of renaming");
			last;
		}

		next if $file_old eq $file_new;

		if(&fixname::fn_rename ($file_old, $file_new))
		{
			&misc::plog(4, "br: renamed '$file_old' -> '$file_new'");

			push @config::undo_pre, "$dir/$file_old";
			push @config::undo_cur, "$dir/$file_new";
			push @new_a, $file_old;
			push @new_b, $file_new;
			&misc::plog(2, "block rename performed");
			next;
		}
		&misc::plog(0, "block rename failed !: '$file_old' -> '$file_new'");
	}
	&br_show_lists("Block Rename Results", \@new_a, \@new_b);
	&txt_reset;

	$config::RUN = 0;
	return 1;
}

sub br_readdir
{
	my @dir_contents	= ();
	my @dir_clean		= ();

	&misc::plog(3, "br_readdir: '$dir'");

	opendir(DIR, $dir) or &main::quit("sub br_readdir: can't open directory '$dir', $!");
	@dir_contents = CORE::readdir(DIR);
	closedir DIR;

	for my $file(@dir_contents)
	{
		next if $file eq '.' || $file eq '..' || $file eq '';

		next if !$config::hash{proc_dirs}		{value} && -d $file;
		next if !$config::hash{ignore_file_type}{value} && $file !~ /\.($config::hash{file_ext_2_proc}{value})$/i;
		next if  $config::hash{filter}			{value} && !&filter::match($file);

		push @dir_clean, $file;
	}
	return &misc::ci_sort(@dir_clean);
}


1;

