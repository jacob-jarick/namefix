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
	$main::STOP		= 0;
	$main::id3_change	= 0;
        $main::change 		= 0;
        $main::suggestF 	= 0;
        $main::tmpfilefound 	= 0;
        $main::enum_count 	= 0;
        $main::tags_rm		= 0;
        $main::last_recr_dir 	= "";
        $main::percent_done	= 0;

        # escape replace word if regexp is disabled
        $main::rpwold_escaped = $main::rpwold;
	$main::rpwold_escaped = quotemeta $main::rpwold			if($config::hash{FILTER_REGEX}{value} == 1);

	# update killword list if file exists
        @main::kill_words_arr = misc::readsf("$main::killwords_file")	if(-f $main::killwords_file);

	# update kill pattern array if file exists
        @main::kill_patterns_arr = &misc::readf($main::killpat_file)	if(-f $main::killpat_file);

	# update casing list if file exists
        @main::word_casing_arr = &misc::readf($main::casing_file)	if(-f $main::casing_file);

        # update escaped list of kill_word_arr
	@main::kill_words_arr_escaped = ();
	for my $word(@main::kill_words_arr)
	{
		push (@main::kill_words_arr_escaped, quotemeta $word);
	}
}

sub run
{
	if($main::LISTING)
	{
		misc::plog(0, "sub run::namefix: error, a listing is currently being preformed - aborting rename");
		return 0;
	}
	elsif($main::RUN)
	{
		misc::plog(0, "sub run::namefix: error, a rename is currently being preformed - aborting rename");
		return 0;
	}

	$main::RUN		= 1;
	&dir_hlist::draw_list if !$main::CLI;

        my $t_s 		= "";	# tmp string

        $main::orig_dir		= cwd;
        chdir $main::dir;
	$main::dir		= cwd();
	&undo::clear;
	prep_globals;

	if(!$main::CLI)
	{
		&dir_hlist::hlist_clear;
		nf_print::p("..");
	}

        if(!$main::recr)
        {
		my @dirlist = &dir::dir_filtered($main::dir);

		my $count = 1;
		my $total = scalar @dirlist;

                foreach my $f (@dirlist)
                {
			$main::percent_done = int(($count++ / $total) * 100);
			&main::quit("sub run: \$f is undef\n")			if ! defined $f;
			&main::quit("sub run: \$f eq ''\n")			if ($f eq '');
			&main::quit("sub run: \$f '$f' is not a dir or file\n")	if (!-f $f && !-d $f);

			&fixname::fix($f, cwd)	if -f $f || ($main::proc_dirs && -d $f);
                }
        }
        if($main::recr)
        {
		&misc::plog(4, "sub run::namefix: recursive mode");
		@main::find_arr = ();
		find(\&find_fix, "$main::dir");
		&find_fix_process;
        }

	# print info

        $t_s = "have";
        $t_s = "would have" if ($main::testmode);

        &misc::plog(1, "$main::change files $t_s been modified");
	&misc::plog(1, "$main::id3_change mp3s tags $t_s been updated.")			if($config::hash{id3_mode}{value});
        &misc::plog(1, "$main::tags_rm mp3 tags $t_s been removed")				if($main::tags_rm);
	&misc::plog(0, "unable to rename $main::suggestF files.\nTry enabling \"FS Fix\".")	if($main::suggestF != 0);
	&misc::plog(0, "tmp file found. check the following files.\n$main::tmpfilelist\n")	if($main::tmpfilefound);

	# cleanup

	$main::testmode = 1;	# return to test mode for safety :)
	$main::RUN = 0;		# finished renaming - turn off run flag
	chdir $main::dir;	# return to users working dir
}

sub find_fix
{
	my $file = $_;
	my $d = cwd();
	push @main::find_arr, "$d/$file";
	return 1;
}

sub find_fix_process
{
	# this sub should recieve an array of files from find_fix
	my $dir = "";

	my $count = 1;
	my $total = scalar @main::find_arr;
	$main::percent_done = 0;

	for my $file(@main::find_arr)
	{
		$main::percent_done = int(($count++ / $total) * 100);

		$file =~ m/^(.*)\/(.*?)$/;
		&fixname::fix($2, $1);
	}
	return 1;
}

1;