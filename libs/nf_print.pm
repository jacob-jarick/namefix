package nf_print;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;
use Cwd;
use Carp;
use Data::Dumper::Concise;


#--------------------------------------------------------------------------------------------------------------
# namefix print
#--------------------------------------------------------------------------------------------------------------

sub p
{
	my $file1	= shift;
	my $file2	= shift;
	my $ref1	= shift;
	my $ref2	= shift;

	if($config::CLI)
	{
		&cli_print::print($file1, $file2, $ref1, $ref2);
		return;
	}

	&dir_hlist::fn_update_delay;

	if(defined $file2 && $file2 eq "<MSG>")
	{
		&misc::plog(1, "$file1\n");	# just a message
		return 1;
	}

	my $NEWFILE	= 0;
	my $hlpos	= $config::hl_counter;	# short hand ref

	$config::hl_counter++;			# now we have a ref, incr for next time

	# add blank line in hlist
	if(defined $file2 && $file2 eq '<BLANK>')
	{
		$dir_hlist::hlist->add
		(	$hlpos,
			-data=>['', '', '']
		);
		return;
	}

	$config::hlist_file_new = $file1;
	if(defined $file2 && $file2 ne '' && !$config::LISTING)
	{
		$NEWFILE = 1;
		$config::hlist_file_new = $file2;
	}

	# listing - file1 must be a file/dir
	if(!$NEWFILE && !(-f $file1 || -d $file1) )
	{
		&main::quit("nf_print: \$file1 $file1 not a file/dir - listing failure ?\n");
	}

	# renaming / previewing rename - file2 must be a file/dir
	if($NEWFILE && !(-f $file2 || -d $file2) )
	{
		&main::quit("nf_print: \$file2 $file2 not a file/dir - rename failed ?\n");
		return 1;
	}

	$config::hlist_file = $file1;
	my $arrow = " -> ";

	$dir_hlist::hlist->add
	(
		$hlpos,
		-data=>[$config::hlist_file, $config::hlist_cwd, $config::hlist_file_new]
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
			-image=>$config::folderimage
		);
	}
	else
	{
		$dir_hlist::hlist->itemCreate
		(
			$hlpos,
			$count++,
			-itemtype=>'imagetext',
			-image=>$config::fileimage
		);
	}

	$config::hlist_file_row = $count;
	$dir_hlist::hlist->itemCreate($hlpos, $count++, -text => $file1);

	return if ($file1 eq ".." || -d $file1);

	if($config::hash{id3_mode}{value})
	{
		&main::quit("nf_print id3_mode enabled but \$ref1 is undef\n") if !defined $ref1;
# 		print "p: using \$ref1\n" . Dumper($ref1);
		my %h = %$ref1;

		for my $k(sort {$mp3::id3_order{$a} <=> $mp3::id3_order{$b}} keys %mp3::id3_order)
		{
			&main::quit("nf_print::p \$ref1 \$h{$k} is undef\n") if ! defined $h{$k};
			$dir_hlist::hlist->itemCreate($hlpos, $count++, -text => $h{$k});
		}
	}
	return if(!$NEWFILE);

	$dir_hlist::hlist->itemCreate($hlpos, $count++, -text => "$arrow");
	$config::hlist_newfile_row = $count;
	$dir_hlist::hlist->itemCreate($hlpos, $count++, -text => "$file2");

	if($config::hash{id3_mode}{value})
	{
		&main::quit("nf_print id3_mode enabled but \$ref2 is undef\n") if !defined $ref2;
		my %h = %$ref2;
		for my $k(sort {$mp3::id3_order{$a} <=> $mp3::id3_order{$b}} keys %mp3::id3_order)
		{
			&main::quit("nf_print::p \$ref2 \$h{$k} is undef\n") if ! defined $h{$k};
			$dir_hlist::hlist->itemCreate($hlpos, $count++, -text => $h{$k});
		}
		return;
	}
}

1;
