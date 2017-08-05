package nf_print;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;
use Cwd;
use Carp;

#--------------------------------------------------------------------------------------------------------------
# namefix print
#--------------------------------------------------------------------------------------------------------------

sub p
{
	my $file1	= shift;
	my $file2	= shift;

	&dir_hlist::fn_update_delay;

	if($file2 eq "<MSG>")
	{
		&misc::plog(1, "$file1\n");	# just a message
		return 1;
	}

	my $ref1	= shift;
	my $ref2	= shift;
	my $hlpos	= $main::hl_counter;	# short hand ref
	$main::hl_counter++;	# now we have a ref, incr for next time
	my $NEWFILE	= 0;

	$main::hlist_file_new = $file1;
	if(defined $file2 && $file2 ne '' && !$main::LISTING)
	{
		$NEWFILE = 1;
		$main::hlist_file_new = $file2;
	}

	print "p: file1 = $file1, file2 = $file2, \$NEWFILE = $NEWFILE\n";

	# file check - if no file passed, return

	# listing - file1 must be a file/dir
	if(!$NEWFILE && !(-f $file1 || -d $file1) )
	{
		&misc::plog(1, "nf_print: \$file1 $file1 not a file/dir - listing failure ?\n");
		&misc::plog(1, "$file1 -> $file2\n");
		return 1;
	}
	# renaming / previewing rename - file2 must be a file/dir
	if($NEWFILE && !(-f $file2 || -d $file2) )
	{
		&misc::plog(1, "nf_print: \$file2 $file2 not a file/dir - rename failed ?\n");
		&misc::plog(1, "$file1 -> $file2\n");
		return 1;
	}

	$main::hlist_file = $file1;
	my $arrow = " -> ";

	$dir_hlist::hlist->add
	(
		$hlpos,
		-data=>[$main::hlist_file, $main::hlist_cwd, $main::hlist_file_new]
	);
	my $count = 0;

	if	# if file is a directory, attach dir icon
	(
		$file1 eq ".."		||	# .. doesnt get detected as a dir when renaming, identify by value instead
		(!$NEWFILE && -d $file1)||	# listing check if s1 is file
		( $NEWFILE && -d $file2)	# file renamed, check if s2 is file :)
	)
	{
		$dir_hlist::hlist->itemCreate
		(
			$hlpos,
			$count++,
			-itemtype=>'imagetext',
			-image=>$main::folderimage
		);
	}
	else
	{
		$dir_hlist::hlist->itemCreate
		(
			$hlpos,
			$count++,
			-itemtype=>'imagetext',
			-image=>$main::fileimage
		);
	}

	$dir_hlist::hlist->itemCreate($hlpos, $count++, -text => $file1);
	$main::hlist_file_row = 1;
	if($file1 eq ".." || -d $file1)
	{
		return;
	}

	if($config::hash{id3_mode}{value})
	{
		croak "nf_print id3_mode enabled but \$ref1 is undef\n" if !defined $ref1;
		my %h = %$ref1;

		for my $k(sort {$mp3::id3_order{$a} <=> $mp3::id3_order{$b}} keys %mp3::id3_order)
		{
			$dir_hlist::hlist->itemCreate($hlpos, $count++, -text => $h{$k});
		}
	}

	if(!$NEWFILE)
	{
		return;
	}
	$dir_hlist::hlist->itemCreate($hlpos, $count++, -text => "$arrow");
	$main::hlist_newfile_row = $count;
	$dir_hlist::hlist->itemCreate($hlpos, $count++, -text => "$file2");

	if($config::hash{id3_mode}{value})
	{
		$dir_hlist::hlist->itemCreate($hlpos, $count++, -text => "$arrow");
		$dir_hlist::hlist->itemCreate($hlpos, $count++, -text => $file2);

		croak "nf_print id3_mode enabled but \$ref2 is undef\n" if !defined $ref2;
		my %h = %$ref2;
		for my $k(sort {$mp3::id3_order{$a} <=> $mp3::id3_order{$b}} keys %mp3::id3_order)
		{
			$dir_hlist::hlist->itemCreate($hlpos, $count++, -text => $h{$k});
		}
		return;
	}
}

1;