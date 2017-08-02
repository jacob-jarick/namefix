package nf_print;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;
use Cwd;

#--------------------------------------------------------------------------------------------------------------
# namefix print
#--------------------------------------------------------------------------------------------------------------

sub p
{
	if($main::CLI)		# redirect old print calls for CLI mode
	{
		&misc::plog(1, "sub nf_print: use of this sub in CLI mode is depreciated");
		&cli_print(@_);
		return 1;
	}

	my $s1 = shift;
	my $s2 = shift;

	$main::hlist_file = $s1;
	my $c = "";
	my $arrow = " -> ";
	chomp $s1;

	# cli print does not guess at how to print anylonger
	# it expects <MSG> for plain text
	# the gui print will recieve the same treatment in the future.
	if($s2 eq "<MSG>")
	{
		$s2 = $s1;
	}

	if(!$s2)
	{
		$s2 = "";
		$main::hlist_file_new = $s1;
	}
	else
	{
		chomp $s2;
		$main::hlist_file_new = $s2;
	}

	&misc::plog(3, "sub nf_print: \"$s1\", \"$s2\"");

	if(!$main::LISTING && !$main::testmode)	# files are being renamed - not a dir list or preview
	{
		$main::hlist_file = $s2;
	}

	$dir_hlist::hlist->add
	(
		$main::hl_counter,
		-data=>[$main::hlist_file, $main::hlist_cwd, $main::hlist_file_new]
	);

	if	# if file is a directory, attach dir icon
	(
		$s1 !~ /^\s+$/ && 					# for some reason -d \s+ returns positive, so check for it here.
		(
			$s1 eq ".." ||					# .. doesnt get detected as a dir when renaming, identify by value instead
			(($main::LISTING || $main::testmode) && -d $s1) ||	# listing check if s1 is file
			(!$main::LISTING && -d $s2)			# file renamed, check if s2 is file :)
		)
	)
	{
		&misc::plog(4, "sub nf_print: \"$s1\" is a dir, attaching dir icon");
		$dir_hlist::hlist->itemCreate
		(
			$main::hl_counter,
			0,
			-itemtype=>'imagetext',
			-image=>$main::folderimage
		);
	}
	elsif	# if file is file, attach file icon
	(
		(($main::LISTING || $main::testmode) && -f $s1) ||
		(!$main::LISTING && -f $s2)
	)
	{
		&misc::plog(4, "sub nf_print: \"$s1\" is a file, attaching file icon");
		$dir_hlist::hlist->itemCreate
		(
			$main::hl_counter,
			0,
			-itemtype=>'imagetext',
			-image=>$main::fileimage
		);
	}
	else	# just been given text to print, no icon and no arrow
	{
		$c = cwd();
		&misc::plog(4, "sub nf_print: \"$s1\" not detected as a file / dir, attaching black icon");
		$arrow = "";
		$dir_hlist::hlist->itemCreate
		(
			$main::hl_counter,
			0,
			-itemtype => "text",
			-text => " "
		);
	}

	if($main::id3_mode == 1)
	{
		&misc::plog(4, "sub nf_print: id3_mode enabled");
		my $art = shift;
		my $tit = shift;
		my $tra = shift;
		my $alb = shift;
		my $com = shift;
		my $gen = shift;
		my $year = shift;

		$dir_hlist::hlist->itemCreate($main::hl_counter, 1, -text => "$s1");
		$main::hlist_file_row = 1;

		if($art)
		{
			$dir_hlist::hlist->itemCreate($main::hl_counter, 2, -text => "$art");
		}
		if($tra)
		{
			$dir_hlist::hlist->itemCreate($main::hl_counter, 3, -text => "$tra");
		}
		if($tit)
		{
			$dir_hlist::hlist->itemCreate($main::hl_counter, 4, -text => "$tit");
		}
		if($alb)
		{
			$dir_hlist::hlist->itemCreate($main::hl_counter, 5, -text => "$alb");
		}

		if($gen)
		{
			$dir_hlist::hlist->itemCreate($main::hl_counter, 6, -text => "$gen");
		}

		if($year)
		{
			$dir_hlist::hlist->itemCreate($main::hl_counter, 7, -text => "$year");
		}

		if($com)
		{
			$dir_hlist::hlist->itemCreate($main::hl_counter, 8, -text => "$com");
		}

		if($main::LISTING == 0) # if renaming or previewing print 'after' fields
		{
			my $newart = shift;
			my $newtit = shift;
			my $newtra = shift;
			my $newalb = shift;
			my $newcom = shift;
			my $newgen = shift;
			my $newyear = shift;

			if($s1 ne "..")
			{
				&misc::plog(4, "sub nf_print: id3_mode, renaming mode, adding new fields");
				$dir_hlist::hlist->itemCreate($main::hl_counter, 9, -text => "$arrow");
				$dir_hlist::hlist->itemCreate($main::hl_counter, 10, -text => "$main::hlist_file_new");
				$main::hlist_newfile_row = 10;

				if($newart)
				{
					$dir_hlist::hlist->itemCreate($main::hl_counter, 11, -text => "$newart");
				}
				if($newtra)
				{
					$dir_hlist::hlist->itemCreate($main::hl_counter, 12, -text => "$newtra");
				}
				if($newtit)
				{
					$dir_hlist::hlist->itemCreate($main::hl_counter, 13, -text => "$newtit");
				}
				if($newalb)
				{
					$dir_hlist::hlist->itemCreate($main::hl_counter, 14, -text => "$newalb");
				}
				if($newgen)
				{
					$dir_hlist::hlist->itemCreate($main::hl_counter, 15, -text => "$newgen");
				}
				if($newyear)
				{
					$dir_hlist::hlist->itemCreate($main::hl_counter, 16, -text => "$newyear");
				}
				if($newcom)
				{
					$dir_hlist::hlist->itemCreate($main::hl_counter, 17, -text => "$newcom");
				}
			}
		}
	}
	else
	{
		if(!$s2)
		{
			$s2 = $s1;
		}
		$dir_hlist::hlist->itemCreate($main::hl_counter, 1, -text => "$s1");
		$main::hlist_file_row = 1;

		if($main::LISTING == 0)
		{
			if($s1 ne "..")
			{
				&misc::plog(4, "sub nf_print: normal mode, renaming adding new fields");
				$dir_hlist::hlist->itemCreate($main::hl_counter, 2, -text => "$arrow");
				$dir_hlist::hlist->itemCreate($main::hl_counter, 3, -text => "$s2");
				$main::hlist_newfile_row = 3;
			}
		}
	}
	$main::hl_counter++;
	&dir_hlist::fn_update_delay;
}

1;