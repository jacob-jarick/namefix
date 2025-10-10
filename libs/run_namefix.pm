package run_namefix;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;

use File::Find;

use Cwd;
use Carp;

#--------------------------------------------------------------------------------------------------------------
# Run Namefix
#--------------------------------------------------------------------------------------------------------------

sub prep_globals
{
	# reset misc vars
	$config::id3_change			= 0;
	$globals::change 			= 0;
	$globals::SUGGEST_FSFIX 	= 0;
	$globals::FOUND_TMP 		= 0;
	$globals::tags_rm_count		= 0;
	$config::percent_done		= 0;
	$fixname::enum_count		= 0;
	$globals::last_recr_dir 	= '';

	# escape replace word if regexp is disabled
	$config::ins_str_old_escaped = $config::hash{ins_str_old}{value};
	$config::ins_str_old_escaped = quotemeta $config::hash{ins_str_old}{value}	if($config::hash{filter_regex}{value} == 1);

	# update killword list if file exists
	@globals::kill_words_arr = misc::readsf("$globals::killwords_file")	if(-f $globals::killwords_file);

	# update kill pattern array if file exists
	@globals::kill_patterns_arr = &misc::readf($globals::killpat_file)	if(-f $globals::killpat_file);

	# update casing list if file exists
	@globals::word_casing_arr = &misc::readf($globals::casing_file)		if(-f $globals::casing_file);
}

sub run
{
	if($globals::LISTING)
	{
		&misc::plog(0, "sub run::namefix: error, a listing is currently being performed - aborting rename");
		return 0;
	}
	elsif(&state::busy())
	{
		&misc::plog(0, "aborting rename due to state is busy");
		return 0;
	}

	&state::set('run');
	&dir_hlist::draw_list if !$globals::CLI;

	my $t_s 			= '';	# tmp string

	$config::orig_dir	= cwd;
	chdir $globals::dir;
	$globals::dir		= cwd;
	&undo::clear;
	$fix_name::last_dir	= '';
	prep_globals;

	if(!$globals::CLI)
	{
		&dir_hlist::hlist_clear();
		&nf_print::parent_dir();
	}

	# non recursive mode
	if(!$config::hash{recursive}{value})
	{
		my @dirlist = &dir::dir_filtered($globals::dir);

		my $count = 1;
		my $total = scalar @dirlist;

		foreach my $f (@dirlist)
		{
			if(&state::check('stop'))
			{
				&misc::plog(1, "run stopped by user");
				last;	# DONT RETURN, let cleanup happen below
			}

			$config::percent_done = int(($count++ / $total) * 100);

			&misc::quit("sub run: \$f is undef\n")					if ! defined $f;
			&misc::quit("sub run: \$f eq ''\n")						if $f eq '';
			&misc::quit("sub run: \$f '$f' is not a dir or file\n")	if !-f $f && !-d $f;

			my ($d, $fn, $p) =  &misc::get_file_info($f);
			&fixname::fix($fn)	if -f $f || ($config::hash{proc_dirs}{value} && -d $f);
		}
	}

	# recursive mode
	if($config::hash{recursive}{value})
	{
		&misc::plog(4, "recursive mode");
		@globals::find_arr = ();
		find(\&find_fix, "$globals::dir");
		&find_fix_process;
	}

	# print info

	$t_s = "have";
	$t_s = "would have" if ($globals::PREVIEW);

	&misc::plog(2, "$globals::change files $t_s been modified");
	&misc::plog(2, "$config::id3_change mp3s tags $t_s been updated.")							if($config::hash{id3_mode}{value});
	&misc::plog(2, "$globals::tags_rm_count mp3 tags $t_s been removed")						if($globals::tags_rm_count);
	&misc::plog(2, "$globals::exif_rm_count image files exif data $t_s been removed")			if($globals::exif_rm_count);
	&misc::plog(0, "unable to rename $globals::SUGGEST_FSFIX files.\nTry enabling \"FS Fix\".")	if($globals::SUGGEST_FSFIX != 0);
	&misc::plog(0, "tmp file found. check the following files.\n$globals::tmpfilelist\n")		if($globals::FOUND_TMP);

	# above loops (recursive and non-recursive) may have been terminated by user, note here
	if(&state::check('stop'))
	{
		&misc::plog(1, "STOP detected, run terminated by user");
	}

	# cleanup
	chdir $globals::dir;	# return to users working dir

	&state::set('idle');	# finished renaming - turn off run flag
}

sub find_fix
{
	my $file = $_;
	my $d = cwd;

	my $path = "$d/$file";

	push @globals::find_arr, $path;
	return 1;
}

sub find_fix_process
{
	# this sub should recieve an array of files from find_fix
	my $dir		= '';
	my $count	= 1;
	my $total	= scalar @globals::find_arr;

	$config::percent_done = 0;

	for my $file(@globals::find_arr)
	{
		if(&state::check('stop'))
		{
			&misc::plog(1, "recursive run stopped by user");
			return;
		}

		$config::percent_done = int(($count++ / $total) * 100);
		&fixname::fix($file);
	}
	return 1;
}

1;
