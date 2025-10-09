# =============================================================================================================
# directory listing related functions
# =============================================================================================================

package dir;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;

use Cwd;
use File::Find;
use File::Spec;

#--------------------------------------------------------------------------------------------------------------
# List Directory
#--------------------------------------------------------------------------------------------------------------

sub ls_dir
{
	&run_namefix::prep_globals;

	if(&state::busy)
	{
		&misc::plog(1,"BUSY, aborting new list attempt");
		return;
	}

	&state::set('list');
	$config::percent_done	= 0;

	$globals::dir			= cwd;

	my @file_list			= ();
	my @dirlist				= &dir_filtered($globals::dir);

	&dir_hlist::draw_list;

	&nf_print::parent_dir();

	if($config::hash{recursive}{value})
	{
		@globals::find_arr = ();
		find(\&run_namefix::find_fix, $globals::dir);
		&ls_dir_find_fix;

		&state::set('idle');
		return;
	}

	my $count				= 1;
	my $total				= scalar @dirlist + scalar @file_list;
	$config::percent_done	= int(($count / $total) * 100);

	for my $f (@dirlist)
	{
		if(&state::check('stop'))
		{
			&misc::plog(1, "listing stopped by user");
			&state::set('idle');
			return;
		}

		$count++;
		$config::percent_done = int(($count / $total) * 100);

		next if $f eq '..';
		if(-d $f)
		{
			&ls_dir_print($f);	# print directorys 1st
			next;
		}
		push @file_list, $f;
	}

	for my $f (@file_list)
	{
		$count++;
		$config::percent_done = int(($count / $total) * 100);

		if(&state::check('stop'))
		{
			&misc::plog(1, "listing stopped by user");
			&state::set('idle');
			return;
		}
		&ls_dir_print($f);		# then print the file array after all dirs have been printed
	}
	
	&state::set('idle');
	return;
}

#--------------------------------------------------------------------------------------------------------------
# ls_dir_print
#--------------------------------------------------------------------------------------------------------------

sub ls_dir_find_fix
{
	# this sub should recieve an array of files from find_fix

	my @list	= @globals::find_arr;
	my $file	= '';

	$config::percent_done = 0;
	my $total = scalar @globals::find_arr;
	my $count = 1;

	for my $file(@globals::find_arr)
	{
		$config::percent_done = int(($count++/$total) * 100);

		$file		=~ m/^(.*)\/(.*?)$/;
		my $f		= $2;
		my $fdir	= File::Spec->abs2rel($file);

		&ls_dir_print($file);
	}
	return 1;
}

# this function is only called from ls_dir & ls_dir_find_fix

sub ls_dir_print
{

	if(&state::check('stop'))
	{
		&misc::plog(1, "listing stopped by user");
		# as this has a return it is up to the calling function to set idle
		return;
	}

	my $file = shift;

	&misc::quit("ls_dir_print \$file is undef\n")	if ! defined $file;
	&misc::quit("ls_dir_print \$file eq ''\n")		if $file eq '';

	return if $file eq '.';

	# recursive padding

	if(-d $file && $config::hash{recursive}{value})
	{
		&nf_print::blank();
		&nf_print::p($file);
		return;
	}

	# check for audio tags
	if($config::hash{id3_mode}{value} && -f $file)
	{
		# Check if $file is already a full path or just a filename
		my $full_path;
		if(File::Spec->file_name_is_absolute($file))
		{
			$full_path = $file;  # Already a full path
		}
		else
		{
			$full_path = "$globals::dir/$file";  # Just a filename, construct full path
		}
		
		my $ref = &mp3::get_tags($full_path);
		&nf_print::p($file, undef, $ref);
		return;
	}
	&nf_print::p($file);
}

#--------------------------------------------------------------------------------------------------------------
# Dir Dialog
#--------------------------------------------------------------------------------------------------------------

sub dialog
{
	my $old_dir = $globals::dir;

	my $dd_dir = $main::mw->chooseDirectory
	(
		-initialdir=>	$globals::dir,
		-title=>		"Choose a directory"
	);

	if($dd_dir)
	{
		$globals::dir = $dd_dir;
		chdir $globals::dir;
		&ls_dir;
	}
	else
	{
		$globals::dir = $old_dir;
	}
}

#--------------------------------------------------------------------------------------------------------------
# fn_readdir, also removes . and .. from listing which nf needs
#--------------------------------------------------------------------------------------------------------------

sub fn_readdir
{
	my $dir				= shift;
	my @dirlist			= ();
	my @dirlist_clean	= ();
	my @d				= ();

	opendir(DIR, $dir) or &misc::quit("can't open dir \"$dir\": $!");
	@dirlist = CORE::readdir(DIR);
	closedir DIR;

	# -- make sure we dont have . and .. in array
	for my $item(@dirlist)
	{
		next if $item eq '.' || $item eq '..';
		push @dirlist_clean, $item;
	}

	@dirlist = &misc::ci_sort(@dirlist_clean);  # sort array
	return @dirlist;
}

sub dir_filtered
{
	my $dir		= shift;
	my @d		= ();
	my @dirlist	= &fn_readdir($dir);

	for my $file (@dirlist)
	{
		# $file is dir automatically fail filter
		next if !&state::check('list') && !$config::hash{proc_dirs}{value} && -d $file;
		next if $config::hash{filter}{value} && !&filter::match($file);

		push @d, $file;
	}
	return @d;
}

1;
