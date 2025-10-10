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
	&misc::quit("CLI should not use p") if($globals::CLI);

	my $file1		= shift;
	my $file2		= shift;
	my $ref1		= shift;	# if id3 mode, hash ref of old tags
	my $ref2		= shift;	# if id3 mode, hash ref of new tags

	my $count		= 0;

	my $target_file = &set_target($file1, $file2);

	my $hlpos	= $dir_hlist::counter++;	# now we have a ref, incr for next time

	my ($dir, $file_name, $path) =  &misc::get_file_info($target_file);	# we only use $path
	{
		my $tmp1 = $file1;
		my $tmp2 = $file2;

		# remove directory if any
		$tmp1 =~ s/^\.*(\/|\\)//;
		$tmp2 =~ s/^\.*(\/|\\)// if defined $tmp2;

		&dir_hlist::info_add($hlpos, $path, $tmp1, $tmp2);
	}

	if(&state::check('run'))
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
			-image=>	$globals::folderimage
		);
	}
	else
	{
		$dir_hlist::hlist->itemCreate
		(
			$hlpos,
			$count++,
			-itemtype=>	'imagetext',
			-image=>	$globals::fileimage
		);
	}

	$globals::hlist_file_row = $count;

	my $file1_clean	= $file_name;
	$file1_clean	= $path if $config::hash{recursive}{value} && -d $path;

	$dir_hlist::hlist->itemCreate($hlpos, $count++, -text => $file1_clean);

	return if (-d $file1);

	if($config::hash{id3_mode}{value})
	{
		&misc::quit("nf_print id3_mode enabled but \$ref1 is undef\n") if !defined $ref1;
		my %h = %$ref1;

		for my $k(sort {$mp3::id3_order{$a} <=> $mp3::id3_order{$b}} keys %mp3::id3_order)
		{
			&misc::quit("nf_print::p \$ref1 \$h{$k} is undef\n") if ! defined $h{$k};
			$dir_hlist::hlist->itemCreate($hlpos, $count++, -text => $h{$k});
		}
	}

	# finish here if list mode	
	return if &state::check('list');
	
	# stop mode shouldn't get here but just in case
	return if &state::check('stop');

	# ------------------------------------------------------------------------------------------------
	# Start of rename / preview section

	my $file2_clean				= $file2;
	$file2_clean				=~ s/^.*\///;
	$globals::hlist_newfile_row	= $count;

	$dir_hlist::hlist->itemCreate($hlpos, $count++, -text => $arrow);
	$dir_hlist::hlist->itemCreate($hlpos, $count++, -text => $file2_clean);

	# ------------------------------------------------------------------------------------------------
	# finished UNLESS id3 mode is enabled

	return if ! $config::hash{id3_mode}{value};

	&misc::quit("nf_print id3_mode enabled but \$ref2 is undef") if !defined $ref2;
	my %h = %$ref2;
	for my $k(sort {$mp3::id3_order{$a} <=> $mp3::id3_order{$b}} keys %mp3::id3_order)
	{
		&misc::quit("nf_print::p \$ref2 \$h{$k} is undef") if ! defined $h{$k};
		$dir_hlist::hlist->itemCreate($hlpos, $count++, -text => $h{$k});
	}
}

# print a blank line
sub blank
{
	&misc::quit("CLI should not use nf_print::blank") if($globals::CLI);

	my $hlpos = $dir_hlist::counter++;	# now we have a ref, incr for next time
	$dir_hlist::hlist->add($hlpos);

	return;
}

# print .. (parent dir)
sub parent_dir
{
	&misc::quit("CLI should not use nf_print::parent_dir") if($globals::CLI);

	my $hlpos = $dir_hlist::counter++;	# now we have a ref, incr for next time

	my $parent_dir = &misc::get_file_parent_dir(cwd);

	&dir_hlist::info_add($hlpos, '..', $parent_dir);
	$dir_hlist::hlist->add($hlpos);
	$dir_hlist::hlist->itemCreate
	(
		$hlpos,
		0,
		-itemtype=>	'imagetext',
		-image=>	$globals::folderimage
	);

	$dir_hlist::hlist->itemCreate($hlpos, 1, -text => '..');
	return;
}

sub dir
{
	&misc::quit("CLI should not use nf_print::dir") if($globals::CLI);

	my $dir1 = shift;
	my $dir2 = shift;

	my $target_dir = &set_target($dir1, $dir2);

	my $hlpos	= $dir_hlist::counter++;	# now we have a ref, incr for next time
}

sub set_target
{
	my $file1	= shift;
	my $file2 	= shift;
	my $target	= undef;

	# determine if dir1 or dir2 is one that exists.
	if(&state::check('list'))
	{
		$target = $file1;
	}
	elsif(&state::check('run'))
	{
		if($globals::PREVIEW)
		{
			$target = $file1;
		}
		else
		{
			$target = $file2;
		}
	}

	&misc::quit("p: \$target is undef")							if ! defined $target;
	&misc::quit("p: \$target eq ''")							if $target eq '';
	&misc::quit("p: \$target '$target' is not a dir or file")	if !-d $target && !-f $target;

	return $target;
}

1;
