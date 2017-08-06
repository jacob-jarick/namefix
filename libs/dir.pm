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

	if($main::LISTING)
	{
		&misc::plog(0, "sub ls_dir: Allready preforming a list, aborting new list attempt");
		return 0;
	}

	$main::percent_done	= 0;
	my @file_list		= ();
	my @dirlist		= &dir_filtered($main::dir);
	$main::STOP		= 0;
	$main::LISTING		= 1;

	chdir $main::dir;	# shift directory, not just list ;)

	$main::dir	= cwd();

	&dir_hlist::draw_list;

        if($main::recr)
        {
		@main::find_arr = ();
	        find(\&find_fix, $main::dir);
		&ls_dir_find_fix;
                $main::LISTING = 0;
                $main::FIRST_DIR_LISTED = 0;
	        return;
        }

	&ls_dir_print('..');

        my $count		= 1;
	my $total		= scalar @dirlist + scalar @file_list;
	$main::percent_done	= int(($count / $total) * 100);

	for my $f (@dirlist)
	{
		$count++;
		$main::percent_done = int(($count / $total) * 100);

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
		$main::percent_done = int(($count / $total) * 100);

		return 0 if $main::STOP;
		&ls_dir_print($f);		# then print the file array after all dirs have been printed
	}
	$main::LISTING = 0;
	$main::FIRST_DIR_LISTED = 0;
	return;
}

#--------------------------------------------------------------------------------------------------------------
# ls_dir_print
#--------------------------------------------------------------------------------------------------------------

sub ls_dir_find_fix
{
	# this sub should recieve an array of files from find_fix

	my @list	= @main::find_arr;
	my $d		= cwd();
	my $file	= '';
	my $dir		= '';

	$main::percent_done = 0;
	my $total = scalar @main::find_arr;
	my $count = 1;

	for $file(@main::find_arr)
	{
		$main::percent_done = int(($count++/$total) * 100);

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
	return 0 if $main::STOP == 1;

	my $file	= shift;
	my $d 		= $main::hlist_cwd	= cwd;

        &main::quit("ls_dir_print \$file is undef\n")	if ! defined $file;
        &main::quit("ls_dir_print \$file eq ''\n")	if $file eq '';
        return if $file eq '.';

	if($file eq "..")
	{
		&nf_print::p('..');
		return;
	}

	# recursive padding

	if(-d $file && $main::recr)
	{
		&nf_print::p(' ', '<BLANK>');
		&nf_print::p("$d/$file", "$d/$file");
		return;
	}

	# check for audio tags
	if($config::hash{id3_mode}{value})
	{
		print "ls_dir_print getting audio tags for $file\n";
		my $ref = &mp3::get_tags($file);
		&nf_print::p($file, undef, $ref);
		return;
	}
	&nf_print::p($file);
}

#--------------------------------------------------------------------------------------------------------------
# Dir Dialog
#--------------------------------------------------------------------------------------------------------------

sub dir_dialog
{
	my $old_dir = $main::dir;

	my $dd_dir = $main::mw->chooseDirectory
	(
		-initialdir=>$main::dir,
		-title=>"Choose a directory"
	);

	if($dd_dir)
	{
		$main::dir = $dd_dir;
                chdir $main::dir;
		&ls_dir;
	}
	else
	{
		$main::dir = $old_dir;
	}
}

#--------------------------------------------------------------------------------------------------------------
# fn_readdir, also removes . and .. from listing which nf needs
#--------------------------------------------------------------------------------------------------------------

sub fn_readdir
{
	my $dir = shift;
	my @dirlist = ();
	my @dirlist_clean = ();
	my @d = ();

	opendir(DIR, "$dir") or die "can't open dir \"$dir\": $!";
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

	for my $i(@dirlist)
	{
		# $i is dir, didnt pass
		next if(!$main::proc_dirs && -d $i && !$main::LISTING);	# ta tibbsy for help
		if($main::FILTER)
		{
			push @d, $i if(&filter::match($i) == 1);	# apply listing filter
		}
		else
		{
			push @d, $i;
		}
	}
	return @d;
}

1;
