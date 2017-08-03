package run_namefix;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;

use Cwd;

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

        my $t_s 		= "";	# tmp string
        my @tmp_arr		= "";

        # escape replace word if regexp is disabled
        if($main::FILTER_REGEX == 1)
        {
        	$main::rpwold_escaped = quotemeta $main::rpwold;
        } else
        {
        	$main::rpwold_escaped = $main::rpwold;
        }

	# update killword list if file exists
        if(-f $main::killwords_file)
        {
		@main::kill_words_arr = &misc::readsf("$main::killwords_file");
	}

	# update escaped list of kill_word_arr
	@main::kill_words_arr_escaped = ();
	for(@main::kill_words_arr)
	{
		push (@main::kill_words_arr_escaped, quotemeta $_);
	}

	# update kill pattern array if file exists
        if(-f $main::killpat_file)
        {
                @main::kill_patterns_arr = &misc::readsf("$main::killpat_file");
        }

	# update casing list if file exists
        if(-f $main::casing_file)
        {
                @main::word_casing_arr = &misc::readf("$main::casing_file");

# 		@main::word_casing_arr_escaped = ();	# clear escaped list
#                 for(@main::word_casing_arr) 		# then update
#                 {
#                 	push (@main::word_casing_arr_escaped, quotemeta $_);
#                 }
        }
}

sub run
{
	&misc::plog(3, "sub run::namefix:");

	if($main::LISTING)
	{
		&misc::plog(0, "sub run::namefix: error, a listing is currently being preformed - aborting rename");
		return 0;
	}
	elsif($main::RUN)
	{
		&misc::plog(0, "sub run::namefix: error, a rename is currently being preformed - aborting rename");
		return 0;
	}

	$main::RUN		= 1;
	$main::orig_dir 	= cwd;

        my $t_s 		= "";	# tmp string
        my @tmp_arr		= "";
	my $txt			= "";
	my $a			= "";
	my $b			= "";

        chdir $main::dir;
	$main::dir = cwd();
	&undo::clear;
	&prep_globals;

	if(!$main::CLI)
	{
		&dir_hlist::hlist_clear;
		&nf_print::p("..", "<MSG>");
	}

        if(!$main::recr)
        {
		my @dirlist = &dir::dir_filtered($main::dir);

		my $count = 1;
		my $total = scalar @dirlist;

                foreach(@dirlist)
                {
			$main::percent_done = int(($count++ / $total) * 100);

                        if(!$_) # stop warnings getting spat out
                        {
                                next;
                        }
                        if($main::proc_dirs)
                        {
                                &fixname::run_fixname($_);
                                next;
                        }
                        elsif(! -d $_)
                        {
                                &fixname::run_fixname($_);
                        }
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
        if ($main::testmode == 1)
        {
        	$t_s = "would have";
        }
        &nf_print::p(" ", "<MSG>");
	&nf_print::p("$main::change files $t_s been modified", "<MSG>");

	if($main::id3_mode)
	{
		&nf_print::p("$main::id3_change mp3s tags $t_s been updated.", "<MSG>");
	}
        if($main::tags_rm)
        {
        	&nf_print::p("$main::tags_rm mp3 tags $t_s been removed", "<MSG>");
        }
        &nf_print::p(" ", "<MSG>");


        if($main::suggestF != 0)
        {
	        &nf_print::p("namefix.pl was unable to rename $main::suggestF files.\nPerhaps you should enable \"FS Fix\".", "<MSG>");
		&nf_print::p(" ", "<MSG>");
        }

        if($main::tmpfilefound != 0)
        {
		&misc::plog(0, "namefix.pl found tmp some of its own tmp files, this should not happen. Please check the following list of files.\n$main::tmpfilelist\n");
	}

	&nf_print::p("namefix.pl $main::version by $main::author", "<MSG>");

        # cleanup

	$main::testmode = 1;	# return to test mode for safety :)
	$main::RUN = 0;		# finished renaming - turn off run flag
	&misc::plog(0, "RUN = $main::RUN");
	chdir $main::dir;	# return to users working dir
}

sub find_fix
{
	my $file = $_;
	my $d = cwd();
	&misc::plog(3, "sub find_fix: \"$d\" \"$file\"");
	push @main::find_arr, "$d/$file";
	return 1;
}


sub find_fix_process
{
	# this sub should recieve an array of files from find_fix

# 	my @list = @main::find_arr;
	my $d = cwd();
	my $dir = "";

	&misc::plog(3, "sub find_fix_process:");
	my $count = 1;
	my $total = scalar @main::find_arr;
	$main::percent_done = 0;

	for my $file(@main::find_arr)
	{
		$main::percent_done = int(($count++ / $total) * 100);

		&misc::plog(4, "sub find_fix_process: list line \"$file\"");
		$file =~ m/^(.*)\/(.*?)$/;
		$dir = $1;
		$file = $2;
		&misc::plog(4, "sub find_fix_process: dir = \"$dir\"");
		&misc::plog(4, "sub find_fix_process: file = \"$file\"");

		chdir $dir;	# change to dir containing file
		&fixname::run_fixname($file);
		chdir $d;	# change back to dir sub started in
	}
	&misc::plog(3, "sub find_fix_process: done");
	return 1;
}

1;