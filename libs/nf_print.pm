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

	my $mode	= &config::mode;

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

	my $hlpos = $dir_hlist::counter;	# short hand ref

	$dir_hlist::counter++;			# now we have a ref, incr for next time

	# add blank line in hlist

	if($file1 eq '..')
	{
		my $parent_dir =  &misc::get_file_parent_dir(cwd);
		&dir_hlist::info_add($hlpos, '..', $parent_dir);
		$dir_hlist::hlist->add($hlpos);
		$dir_hlist::hlist->itemCreate
		(
			$hlpos,
			0,
			-itemtype=>'imagetext',
			-image=>$config::folderimage
		);

		$dir_hlist::hlist->itemCreate($hlpos, 1, -text => '..');

		return;
	}

	if(defined $file2 && $file2 eq '<BLANK>')
	{
		$dir_hlist::hlist->add($hlpos);
		return;
	}

	my $target_file = $file1;
	if(defined $file2 && $file2 ne '' && !$config::LISTING)
	{
		$target_file = $file2;
	}

	$file2 = $file1 if !defined $file2;

	my ($dir, $file_name, $path);
	# listing - file1 must be a file/dir
	($dir, $file_name, $path) =  &misc::get_file_info($file1) if -f $file1 || -d $file1;
	($dir, $file_name, $path) =  &misc::get_file_info($file2) if -f $file2 || -d $file2;

	if(($mode eq 'list' || $mode eq 'preview') && !(-f $file1 || -d $file1) )
	{
		&main::quit("nf_print: \$file1 $file1 not a file/dir - listing failure ?\n");
	}

	# renaming file2 must be a file/dir
	if($mode eq 'rename' && !-f $file2 && !-d $file2 )
	{
		&main::quit("nf_print::p \$file1 '$file1' \$file2 '$file2' not a file/dir - rename failed ?\n");
		return 1;
	}

	my $arrow = ' -> ';

	my $ch_dir = $dir;
	$ch_dir = $path if -d $path;

	$dir_hlist::hlist->add( $hlpos );
	&dir_hlist::info_add($hlpos, $file_name, $dir, $target_file);
	my $count = 0;

	# if a directory attach dir icon
	if(-d $target_file)
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

	my $file1_clean = $file_name;

	if($config::hash{RECURSIVE}{value} && -d $path)
	{
		$file1_clean = $path;
	}

	$dir_hlist::hlist->itemCreate($hlpos, $count++, -text => $file1_clean);

	return if (-d $file1);

	if($config::hash{id3_mode}{value})
	{
		&main::quit("nf_print id3_mode enabled but \$ref1 is undef\n") if !defined $ref1;
		my %h = %$ref1;

		for my $k(sort {$mp3::id3_order{$a} <=> $mp3::id3_order{$b}} keys %mp3::id3_order)
		{
			&main::quit("nf_print::p \$ref1 \$h{$k} is undef\n") if ! defined $h{$k};
			$dir_hlist::hlist->itemCreate($hlpos, $count++, -text => $h{$k});
		}
	}
	return if $mode ne 'rename';

	$dir_hlist::hlist->itemCreate($hlpos, $count++, -text => "$arrow");
	$config::hlist_newfile_row = $count;

	my $file2_clean = $file2;
	$file2_clean =~ s/^.*\///;

	$dir_hlist::hlist->itemCreate($hlpos, $count++, -text => $file2_clean);

	if($config::hash{id3_mode}{value})
	{
		&main::quit("nf_print id3_mode enabled but \$ref2 is undef") if !defined $ref2;
		my %h = %$ref2;
		for my $k(sort {$mp3::id3_order{$a} <=> $mp3::id3_order{$b}} keys %mp3::id3_order)
		{
			&main::quit("nf_print::p \$ref2 \$h{$k} is undef") if ! defined $h{$k};
			$dir_hlist::hlist->itemCreate($hlpos, $count++, -text => $h{$k});
		}
		return;
	}
}

1;
