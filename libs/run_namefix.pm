package run_namefix;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;

use Cwd;
use Carp;

#--------------------------------------------------------------------------------------------------------------
# Run Namefix
#--------------------------------------------------------------------------------------------------------------

sub prep_globals
{
	# reset misc vars
	$config::STOP		= 0;
	$config::id3_change	= 0;
        $config::change 	= 0;
        $config::suggestF 	= 0;
        $config::tmpfilefound 	= 0;
        $config::enum_count 	= 0;
        $config::tags_rm	= 0;
        $config::percent_done	= 0;
        $config::last_recr_dir 	= '';

        # escape replace word if regexp is disabled
        $config::ins_str_old_escaped = $config::ins_str_old;
	$config::ins_str_old_escaped = quotemeta $config::ins_str_old			if($config::hash{FILTER_REGEX}{value} == 1);

	# update killword list if file exists
        @config::kill_words_arr = misc::readsf("$config::killwords_file")	if(-f $config::killwords_file);

	# update kill pattern array if file exists
        @config::kill_patterns_arr = &misc::readf($config::killpat_file)	if(-f $config::killpat_file);

	# update casing list if file exists
        @config::word_casing_arr = &misc::readf($config::casing_file)	if(-f $config::casing_file);

        # update escaped list of kill_word_arr
	@config::kill_words_arr_escaped = ();
	for my $word(@config::kill_words_arr)
	{
		push (@config::kill_words_arr_escaped, quotemeta $word);
	}
}

sub run
{
	if($config::LISTING)
	{
		misc::plog(0, "sub run::namefix: error, a listing is currently being preformed - aborting rename");
		return 0;
	}
	elsif($config::RUN)
	{
		misc::plog(0, "sub run::namefix: error, a rename is currently being preformed - aborting rename");
		return 0;
	}

	$config::RUN		= 1;
	&dir_hlist::draw_list if !$config::CLI;

        my $t_s 		= '';	# tmp string

        $config::orig_dir	= cwd;
        chdir $config::dir;
	$config::dir		= cwd;
	&undo::clear;
	prep_globals;

	if(!$config::CLI)
	{
		&dir_hlist::hlist_clear;
		nf_print::p('..');
	}

        if(!$config::RECURSIVE)
        {
		my @dirlist = &dir::dir_filtered($config::dir);

		my $count = 1;
		my $total = scalar @dirlist;

                foreach my $f (@dirlist)
                {
			$config::percent_done = int(($count++ / $total) * 100);
			&main::quit("sub run: \$f is undef\n")			if ! defined $f;
			&main::quit("sub run: \$f eq ''\n")			if ($f eq '');
			&main::quit("sub run: \$f '$f' is not a dir or file\n")	if (!-f $f && !-d $f);

			&fixname::fix($f, cwd)	if -f $f || ($config::hash{PROC_DIRS}{value} && -d $f);
                }
        }
        if($config::RECURSIVE)
        {
		&misc::plog(4, "sub run::namefix: recursive mode");
		@config::find_arr = ();
		find(\&find_fix, "$config::dir");
		&find_fix_process;
        }

	# print info

        $t_s = "have";
        $t_s = "would have" if ($config::PREVIEW);

        &misc::plog(1, "$config::change files $t_s been modified");
	&misc::plog(1, "$config::id3_change mp3s tags $t_s been updated.")			if($config::hash{id3_mode}{value});
        &misc::plog(1, "$config::tags_rm mp3 tags $t_s been removed")				if($config::tags_rm);
	&misc::plog(0, "unable to rename $config::suggestF files.\nTry enabling \"FS Fix\".")	if($config::suggestF != 0);
	&misc::plog(0, "tmp file found. check the following files.\n$config::tmpfilelist\n")	if($config::tmpfilefound);

	# cleanup

	$config::PREVIEW = 1;	# return to test mode for safety :)
	$config::RUN = 0;	# finished renaming - turn off run flag
	chdir $config::dir;	# return to users working dir
}

sub find_fix
{
	my $file = $_;
	my $d = cwd();
	push @config::find_arr, "$d/$file";
	return 1;
}

sub find_fix_process
{
	# this sub should recieve an array of files from find_fix
	my $dir		= '';
	my $count	= 1;
	my $total	= scalar @config::find_arr;

	$config::percent_done = 0;

	for my $file(@config::find_arr)
	{
		$config::percent_done = int(($count++ / $total) * 100);

		$file =~ m/^(.*)\/(.*?)$/;
		&fixname::fix($2, $1);
	}
	return 1;
}

1;
