# =============================================================================================================
# directory listing related functions
# =============================================================================================================

package dir;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;

use Cwd;

#--------------------------------------------------------------------------------------------------------------
# List Directory
#--------------------------------------------------------------------------------------------------------------

sub ls_dir
{
	&run_namefix::prep_globals;

	&main::quit("sub ls_dir: BUSY, aborting new list attempt") if(&config::busy);

	$config::LISTING	= 1;
	$config::STOP		= 0;
	$config::percent_done	= 0;
	my @file_list		= ();
	my @dirlist		= &dir_filtered($config::dir);

	chdir $config::dir;
	$config::dir = cwd();
	&dir_hlist::draw_list;

        if($config::hash{RECURSIVE}{value})
        {
		@config::find_arr = ();
	        find(\&find_fix, $config::dir);
		&ls_dir_find_fix;
                $config::LISTING = 0;
	        return;
        }

	&ls_dir_print('..');

        my $count		= 1;
	my $total		= scalar @dirlist + scalar @file_list;
	$config::percent_done	= int(($count / $total) * 100);

	for my $f (@dirlist)
	{
		if($config::STOP)
		{
			$config::LISTING = 0;
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

		if($config::STOP)
		{
			$config::LISTING = 0;
			return;
		}
		&ls_dir_print($f);		# then print the file array after all dirs have been printed
	}
	$config::LISTING = 0;
	return;
}

#--------------------------------------------------------------------------------------------------------------
# ls_dir_print
#--------------------------------------------------------------------------------------------------------------

sub ls_dir_find_fix
{
	# this sub should recieve an array of files from find_fix

	my @list	= @config::find_arr;
	my $d		= cwd();
	my $file	= '';
	my $dir		= '';

	$config::percent_done = 0;
	my $total = scalar @config::find_arr;
	my $count = 1;

	for $file(@config::find_arr)
	{
		$config::percent_done = int(($count++/$total) * 100);

		$file	=~ m/^(.*)\/(.*?)$/;
		$dir	= $1;
		$file	= $2;

		chdir $dir;	# change to dir containing file
		&ls_dir_print($file);
		chdir $d;	# change back to dir sub started in
	}
	return 1;
}

# this function is only called from ls_dir & ls_dir_find_fix

sub ls_dir_print
{
	return 0 if $config::STOP == 1;

	my $file	= shift;
	my $d 		= $config::hlist_cwd	= cwd;

        &main::quit("ls_dir_print \$file is undef\n")	if ! defined $file;
        &main::quit("ls_dir_print \$file eq ''\n")	if $file eq '';
        return if $file eq '.';

	if($file eq "..")
	{
		&nf_print::p('..');
		return;
	}

	# recursive padding

	if(-d $file && $config::hash{RECURSIVE}{value})
	{
		&nf_print::p(' ', '<BLANK>');
		&nf_print::p("$d/$file", "$d/$file");
		return;
	}

	# check for audio tags
	if($config::hash{id3_mode}{value})
	{
# 		print "ls_dir_print getting audio tags for $file\n";
		my $ref = &mp3::get_tags($file);
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
	my $old_dir = $config::dir;

	my $dd_dir = $main::mw->chooseDirectory
	(
		-initialdir=>$config::dir,
		-title=>"Choose a directory"
	);

	if($dd_dir)
	{
		$config::dir = $dd_dir;
                chdir $config::dir;
		&ls_dir;
	}
	else
	{
		$config::dir = $old_dir;
	}
}

#--------------------------------------------------------------------------------------------------------------
# fn_readdir, also removes . and .. from listing which nf needs
#--------------------------------------------------------------------------------------------------------------

sub fn_readdir
{
	my $dir			= shift;
	my @dirlist		= ();
	my @dirlist_clean	= ();
	my @d			= ();

	opendir(DIR, "$dir") or &main::quit("can't open dir \"$dir\": $!");
	@dirlist = CORE::readdir(DIR);
	closedir DIR;

	# -- make sure we dont have . and .. in array --
	for my $item(@dirlist)
	{
		next if $item eq "." || $item eq "..";
		push @dirlist_clean, $item;
	}

	@dirlist = &misc::ci_sort(@dirlist);  # sort array
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
		next if !$config::LISTING && (!$config::hash{PROC_DIRS}{value} && -d $file);
		if($config::hash{FILTER}{value})
		{
			push @d, $file if &filter::match($file);	# apply listing filter
		}
		else
		{
			push @d, $file;
		}
	}
	return @d;
}

1;
