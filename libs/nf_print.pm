package nf_print;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;
use Cwd;
use Carp;
use Data::Dumper::Concise;

my $arrow = ' -> ';

#--------------------------------------------------------------------------------------------------------------
# namefix print
#--------------------------------------------------------------------------------------------------------------

sub p
{
	&main::quit("CLI should not use p") if($config::CLI);

	my $file1	= shift;
	my $file2	= shift;
	my $ref1	= shift;
	my $ref2	= shift;
	my $mode	= &config::mode;
	my $hlpos	= $dir_hlist::counter++;	# now we have a ref, incr for next time

	if(defined $file2 && $file2 eq '<BLANK>')
	{
		$dir_hlist::hlist->add($hlpos);
		return;
	}

	# ------------------------------------------------------------------
	# add up directory and return

	if($file1 eq '..')
	{
		my $parent_dir = &misc::get_file_parent_dir(cwd);

		&dir_hlist::info_add($hlpos, '..', $parent_dir);
		$dir_hlist::hlist->add($hlpos);
		$dir_hlist::hlist->itemCreate
		(
			$hlpos,
			0,
			-itemtype=>	'imagetext',
			-image=>	$config::folderimage
		);

		$dir_hlist::hlist->itemCreate($hlpos, 1, -text => '..');
		return;
	}

	# ------------------------------------------------------------------

	my $count	= 0;
	my $target_file	= $file1;
	$target_file	= $file2 if $mode eq 'rename';

	&main::quit("p: \$target_file is undef")							if ! defined $target_file;
	&main::quit("p: \$target_file eq '' is not a file or dir")			if $target_file eq '';
	&main::quit("p: \$target_file '$target_file' is not a file or dir")	if !-f $target_file && !-d $target_file;

	my ($dir, $file_name, $path) =  &misc::get_file_info($target_file);
	{
		my $tmp1 = $file1;
		my $tmp2 = $file2;

		# remove directory if any
		$tmp1 =~ s/^\.*(\/|\\)//;
		$tmp2 =~ s/^\.*(\/|\\)// if defined $tmp2;

		&dir_hlist::info_add($hlpos, $path, $tmp1, $tmp2);
	}

	if($mode eq 'rename')
	{
		$file_name = $file1;
		$file_name =~ s/^.*(\\|\/)//;
	}

	&dir_hlist::fn_update_delay;
	$dir_hlist::hlist->add( $hlpos );

	# if a directory attach dir icon
	if(-d $target_file)
	{
		$dir_hlist::hlist->itemCreate
		(
			$hlpos,
			$count++,
			-itemtype=>	'imagetext',
			-image=>	$config::folderimage
		);
	}
	else
	{
		$dir_hlist::hlist->itemCreate
		(
			$hlpos,
			$count++,
			-itemtype=>	'imagetext',
			-image=>	$config::fileimage
		);
	}

	$config::hlist_file_row = $count;

	my $file1_clean	= $file_name;
	$file1_clean	= $path if $config::hash{RECURSIVE}{value} && -d $path;

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

	return if $mode ne 'rename' && $mode ne 'preview';

	# ------------------------------------------------------------------------------------------------
	# Start of rename / preview section

	my $file2_clean				= $file2;
	$file2_clean				=~ s/^.*\///;
	$config::hlist_newfile_row	= $count;

	$dir_hlist::hlist->itemCreate($hlpos, $count++, -text => $arrow);
	$dir_hlist::hlist->itemCreate($hlpos, $count++, -text => $file2_clean);

	# ------------------------------------------------------------------------------------------------
	# finished UNLESS id3 mode is enabled

	return if ! $config::hash{id3_mode}{value};

	&main::quit("nf_print id3_mode enabled but \$ref2 is undef") if !defined $ref2;
	my %h = %$ref2;
	for my $k(sort {$mp3::id3_order{$a} <=> $mp3::id3_order{$b}} keys %mp3::id3_order)
	{
		&main::quit("nf_print::p \$ref2 \$h{$k} is undef") if ! defined $h{$k};
		$dir_hlist::hlist->itemCreate($hlpos, $count++, -text => $h{$k});
	}
}

1;
