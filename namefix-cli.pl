#!/usr/bin/perl -w

use strict;
use warnings;

use English;
use Cwd;
use MP3::Tag;
use File::Find;
use File::Basename qw(&basename &dirname);

use File::Copy;
use FindBin qw($Bin);

# $0 = location of scipt either full or relative, usefull to determine scripts location

# mems libs
require "$Bin/libs/fixname.pm";
require "$Bin/libs/run_namefix.pm";
require "$Bin/libs/misc.pm";
require "$Bin/libs/config.pm";
require "$Bin/libs/global_variables.pm";
require "$Bin/libs/nf_print.pm";

require "$Bin/libs/dir.pm";
require "$Bin/libs/mp3.pm";
require "$Bin/libs/filter.pm";
require "$Bin/libs/undo.pm";
require "$Bin/libs/html.pm";

require "$Bin/libs/cli/help.pm";
require "$Bin/libs/cli/print.pm";

#--------------------------------------------------------------------------------------------------------------
# define global vars
#--------------------------------------------------------------------------------------------------------------



our $ERROR_STDOUT;
our $id3_art_str;
our $undo_cur_file;
our $id3_gen_str;
our $kill_patterns_arr;
our $space_character;
our $id3_alb_str;
our $enum;
our $truncate;
our $thanks;
our $id3v2_rm;
our $rpwold;
our $word_casing_arr;
our $eaw;
our $faw;
our $rm_digits;
our $id3_com_set;
our $digits;
our $enum_opt;
our $id3_year_str;
our $version;
our $id3_guess_tag;
our $file_ext_2_proc;
our $front_a;
our $ZERO_LOG;
our $id3_alb_set;
our $truncate_style;
our $overwrite;
our $intr_char;
our $links;
our $split_dddd;
our $kill_words_arr;
our $undo_cur;
our $trunc_char;
our $id3_force_guess_tag;
our $debug;
our $id3_gen_set;
our $CLI;
our $todo;
our $end_a;
our $changelog;
our $id3_year_set;
our $enum_pad_zeros;
our $enum_pad;
our $id3v1_rm;
our $id3_art_set;
our $LOG_STDOUT;
our $filter_use_re;
our $truncate_to;
our $sp_char;
our $log_file;
our $undo_pre;
our $id3_com_str;
our $filter_string;
our $recr;
our $about;
our $rpwnew;
our $undo_pre_file;

#--------------------------------------------------------------------------------------------------------------
# load config file if it exists
#--------------------------------------------------------------------------------------------------------------


if(-f $main::config_file)
{
	do $main::config_file;	# executes config file
}

if($main::ZERO_LOG)
{
	&clog;
}

&plog(1, "**** namefix.pl $main::version start *************************************************");
&plog(4, "main: \$Bin = \"$Bin\"");

$main::CLI = 1;	# set cli mode flag

#--------------------------------------------------------------------------------------------------------------
# CLI Variables
#--------------------------------------------------------------------------------------------------------------

my @tmp = ();
my $text = "";

#-------------------------------------------------------------------------------------------------------------
# 1st run check
#-------------------------------------------------------------------------------------------------------------

if(!-f $main::config_file)
{
	&cli_print("No config file found, Creating.", "<MSG>");
	&save_config;
}

if(!-f $main::casing_file)
{
	&cli_print("No Special Word Casing file found, Creating.", "<MSG>");
	&save_file($main::casing_file, join("\n", @main::word_casing_arr));
}

if(!-f $main::killwords_file)
{
	&cli_print("No Kill Words file found, Creating.", "<MSG>");
	&save_file($main::killwords_file, join("\n", @main::kill_words_arr));
}

if(!-f $main::killpat_file)
{
	&cli_print("No Kill Patterns file found, Creating.", "<MSG>");
	&save_file($main::killpat_file, join("\n", @main::kill_patterns_arr));
}

#-------------------------------------------------------------------------------------------------------------
# Startup options
#-------------------------------------------------------------------------------------------------------------

$main::dir = $ARGV[$#ARGV];

if(-d $main::dir)
{
	chdir $main::dir;
	$main::dir = cwd();

	if(!-d $main::dir)
	{
		plog(0, "main: $main::dir is not a directory, cowardly refusing to process it");
		exit 0;
	}
	else
	{
		pop @ARGV;
	}
}
else
{
	$main::dir = cwd;
}

#--------------------------------------------------------------------------------------------------------------
# Parse Options
#--------------------------------------------------------------------------------------------------------------

$main::advance = 1;	# since general cleanup is an option, enable advanced mode by default
			# and have the general cleanup option  turn it off.

$main::ERROR_STDOUT = 1;

for(@ARGV)
{
	# found a short option, process it
	if($_ !~ /^--/ && $_ =~ /^-/ )
	{
		&proc_short_opts($_);
		next;
	}

	if($_ eq "--help")
	{
		&cli_help("help");
		exit 0;
	}
	if($_ eq "--help-short")
	{
		&cli_help("short");
		exit 0;
	}
	if($_ eq "--help-long")
	{
		&cli_help("log");
		exit 0;
	}
	if($_ eq "--help-misc")
	{
		&cli_help("misc");
		exit 0;
	}
	if($_ eq "--help-adv")
	{
		&cli_help("adv");
		exit 0;
	}
	elsif($_ eq "--help-mp3")
	{
		&cli_help("mp3");
		exit 0;
	}
	elsif($_ eq "--help-trunc")
	{
		&cli_help("trunc");
		exit 0;
	}
	elsif($_ eq "--help-enum")
	{
		&cli_help("enum");
		exit 0;
	}
	elsif($_ eq "--help-doc")
	{
		&cli_help("doc");
		exit 0;
	}
	elsif($_ eq "--help-debug")
	{
		&cli_help("debug");
		exit 0;
	}
	elsif($_ eq "--help-hacks")
	{
		&cli_help("hacks");
		exit 0;
	}

	elsif($_ eq "--help-all")
	{
		&cli_help("all");
		exit 0;
	}

	#####################
	# Main Options
	#####################

	elsif($_ eq "--cleanup" || $_ eq "--clean" )
	{
		$main::advance = 0;
	}
	elsif($_ eq "--rename" || $_ eq "--ren")
	{
		$main::testmode = 0;
	}
	elsif($_ eq "--case")
	{
		$main::case = 1;
	}
	elsif($_ eq "--spaces")
	{
		$main::spaces = 1;
	}
	elsif($_ eq "--dots")
	{
		$main::dot2space = 1;
	}
	elsif($_ eq "--regexp")
	{
		 $main::disable_regexp = 0;
	}
  	elsif(/---remove=(.*)/ || /--rm=(.*)/)
 	{
 		$main::replace = 1;
		$main::rpwold = $1;
 	}
	elsif(/--replace=(.*)/ | /--rp=(.*)/)
	{
		if(!$main::replace)
		{
			plog(0, "main: option replace present but remove option not");
			exit;
		}
		$main::rpwnew = $1;
	}
	elsif(/--append-front=(.*)/ || /--af=(.*)/ )
	{
		$main::front_a = 1;
		$main::faw = $1;
	}
	elsif(/--end-front=(.*)/ || /--ea=(.*)/ )
	{
		$main::end_a = 1;
		$main::eaw = $1;
	}
	elsif($_ eq "--rm-words")
	{
		$main::kill_cwords = 1;
	}

	elsif($_ eq "--rm-pat")
	{
		$main::kill_sp_patterns = 1;
	}
	elsif($_ eq "--case-sp")
	{
		$main::sp_word = 1;
	}
	elsif($_ eq "--fs-fix")
	{
		$main::fat32fix = 1;
	}

	#####################
	# Advanced Options
	#####################

	elsif($_ eq "--undo")
	{
		$main::UNDO = 1;
	}

	elsif($_ eq "--recr")
	{
		$main::recr = 1;
	}
	elsif($_ eq "--dir")
	{
		$main::proc_dirs = 1;
	}

	elsif($_ eq "--overwrite")
	{
		$main::overwrite = 1;
	}
 	elsif($_ eq "--all-files")
 	{
 		$main::ig_type = 1;
 	}
	elsif(/--filt=(.*)/)
	{
		$main::filter_string = $1;
	}
	elsif($_ eq "--filt-regexp")
	{
		$main::filter_use_re = 1;
	}
	elsif(/--space-char=(.*)/ || /--spc=(.*)/)
	{
		$main::space_character = $1;
	}
	elsif(/--media-types=(.*)/ || /--mt=(.*)/)
	{
		$main::file_ext_2_proc = $1;
	}

	#######################
	# Truncate options
	######################

	elsif(/-trunc=(.*)/)
	{
		$main::truncate = 1;
		$main::truncate_to = $1;

	}
	elsif(/--trunc-pat=(.*)/)
	{
		$main::truncate_style = $1;
	}
	elsif(/--trunc-ins=(.*)/)
	{
		$main::trunc_char = $1;
	}

	########################
	# Enumerate Options
	########################

 	elsif($_ eq "--enum")
 	{
 		$main::enum = 1;
 	}
	elsif(/--enum-style=(.*)/)
	{
		$main::enum_opt = $1;
	}
	elsif(/--enum-zero-pad=(.*)/)
	{
		$main::enum_pad = 1;
		$main::enum_pad_zeros = $1;
	}

	#####################
	# Misc Options
	#####################

	elsif($_ eq "--int")
	{
		$main::intr_char = 1;
	}

	elsif($_ eq "--scene" || $_ eq "--sc")
	{
		$main::scene = 1;
	}

	elsif($_ eq "--unscene" || $_ eq "--usc")
	{
		$main::unscene = 1;
	}

	elsif($_ eq "--uc-all" || $_ eq "--uc")
	{
		$main::uc_all = 1;
	}

	elsif($_ eq "--lc-all" || $_ eq "--lc")
	{
		$main::lc_all = 1;
	}

	elsif($_ eq "--rm-nc" || $_ eq "--rmc")
	{
		$main::sp_char = 1;
	}
	elsif($_ eq "--rm-starting-digits" || $_ eq "--rsd")
	{
		$main::digits = 1;
	}
	elsif($_ eq "--rm-all-digits" || $_ eq "--rad")
	{
		$main::rm_digits = 1;
	}
	elsif($_ eq "--pad-hyphen" || $_ eq "--ph")
	{
		$main::pad_dash = 1;
	}
	elsif($_ eq "--pad-num" || $_ eq "--pn")
	{
		$main::pad_digits = 1;
	}
	elsif($_ eq "--pad-num-w0" || $_ eq "--p0")
	{
		$main::pad_digits_w_zero = 1;
	}
	elsif($_ eq "--pad-nnnn-wx" || $_ eq "--px")
	{
		$main::split_dddd = 1;
	}

	#####################
	# Hacks Options
	#####################

	elsif($_ eq "--html")
	{
		$main::HTML_HACK = 1;
	}
	elsif(/--browser=(.*)/)
	{
		$main::browser = $1;
	}

	#####################
	# MP3 Options
	#####################

	elsif($_ eq "--id3-guess")
	{
		$main::id3_mode = 1;
		$main::id3_guess_tag = 1;
	}
	elsif($_ eq "--id3-overwrite")
	{
		$main::id3_mode = 1;
		$main::id3_force_guess_tag = 1;
	}
	elsif($_ eq "--id3-rm-v1")
	{
		$main::id3_mode = 1;
		$main::id3v1_rm = 1;
	}
	elsif($_ eq "--id3-rm-v2")
	{
		$main::id3_mode = 1;
		$main::id3v2_rm = 1;
	}
	elsif(/--id3-art=(.*)/)
	{
		$main::id3_mode = 1;
		$main::id3_art_set = 1;
		$main::id3_art_str = $1;
	}
	elsif(/--id3-tit=(.*)/)
	{
		$main::id3_mode = 1;
		$main:: = $1;
	}
	elsif(/--id3-tra=(.*)/)
	{
		$main::id3_mode = 1;
		$main:: = $1;
	}
	elsif(/--id3-alb=(.*)/)
	{
		$main::id3_mode = 1;
		$main::id3_alb_set = 1;
		$main::id3_alb_str = $1;
	}
	elsif(/--id3-gen=(.*)/)
	{
		$main::id3_mode = 1;
		$main::id3_gen_set = 1;
		$main::id3_gen_str = $1;
	}
	elsif(/--id3-yer=(.*)/)
	{
		$main::id3_mode = 1;
		$main::id3_year_set = 1;
		$main::id3_year_str = $1;
	}
	elsif(/--id3-com=(.*)/)
	{
		$main::id3_mode = 1;
		$main::id3_com_set = 1;
		$main::id3_com_str = $1;
	}

	##########################

	elsif(/--debug=(.*)/)
	{
		$main::debug = $1;
	}
	elsif($_ eq "--debug-stdout")
	{
		$main::LOG_STDOUT = 1;
	}

	#############################
	# Document options
	#############################


	elsif($_ eq "--changelog")
	{
		$text = join("", &readf($main::changelog));
		print "$text\n\n";
		exit 1;
	}
	elsif($_ eq "--about")
	{
		$text = join("", &readf($main::about));
		print "$text\n\n";
		exit 1;
	}
	elsif($_ eq "--todo")
	{
		$text = join("", &readf($main::todo));
		print "$text\n\n";
		exit 1;
	}
	elsif($_ eq "--thanks")
	{
		$text = join("", &readf($main::thanks));
		print "$text\n\n";
		exit 1;
	}
	elsif($_ eq "--links")
	{
		$text = join("", &readf($main::links));
		print "$text\n\n";
		exit 1;
	}
	elsif(/--editor=(.*)/)
	{
		$main::editor = $1;
	}
	elsif($_ eq "--ed-config")
	{
		system("$main::editor $main::config_file");
		exit 1;
	}

	elsif($_ eq "--ed-spcase")
	{
		system("$main::editor $main::casing_file");
		exit 1;
	}
	elsif($_ eq "--ed-rmwords")
	{
		system("$main::editor $main::killwords_file");
		exit 1;
	}
	elsif($_ eq "--ed-rmpat")
	{
		system("$main::editor $main::killpat_file");
		exit 1;
	}
	elsif($_ eq "--show-log")
	{
		$text = join("", &readf($main::log_file));
		print "$text\n\n";
		exit 1;
	}

	#############################
	# Save config options
	#############################

	elsif($_ eq "--save-options" || $_ eq "--save-opt" || $_ eq "--save-config")
	{
		&save_config;
		&cli_print("Options Saved, exiting", "<MSG>");
		exit 1;
	}
	else
	{
		&plog(0, "main: unkown long option \"$_\", cowardly refusing to run.");
		exit 0;
	}
}


#--------------------------------------------------------------------------------------------------------------
# Main
#--------------------------------------------------------------------------------------------------------------

if(!$main::testmode && !$main::UNDO)
{
	&clear_undo;
	$main::undo_dir = $main::dir;
	&save_file($main::undo_dir_file, $main::dir);
}

# set main dir, run fixname.....
print "*** Processing dir: $main::dir\n";

&save_file($main::html_file, " ");	# clear html file

&html("<table border=1>");
&html("<TR><TD colspan=2><b>Before</b></TD><TD colspan=2><b>After</b></TD></TR>");


if($main::UNDO)
{
	@main::undo_pre = &readf($main::undo_pre_file);
	@main::undo_cur = &readf($main::undo_cur_file);
	@tmp = &readf($main::undo_dir_file);
	$main::undo_dir = $tmp[0];
	&undo_rename;
}
else
{
	&run_namefix;
}

&html("</table>");

if($main::HTML_HACK)
{
	system("$main::browser $main::html_file");
}

#--------------------------------------------------------------------------------------------------------------
# End
#--------------------------------------------------------------------------------------------------------------

sub proc_short_opts
{
	my $string = shift;
	my @tmp = split(undef, $string);

	for(@tmp)
	{
		#print "tmp = \"$_\"\n";
		if(/h/)
		{
			&cli_help("short");
		}
		elsif($_ eq "-") { next; }
		elsif($_ eq "!") { $main::testmode = 0; }

		elsif($_ eq "c") { $main::case = 1; }
		elsif($_ eq "g") { $main::advance = 0; }
		elsif($_ eq "o") { $main::dot2space = 1; }
		elsif($_ eq "p") { $main::spaces = 1; }
		elsif($_ eq "s") { $main::scene = 1; }
		elsif($_ eq "u") { $main::unscene = 1; }
		elsif($_ eq "x") { $main::disable_regexp = 0; }

		elsif($_ eq "0") { $main::pad_digits_w_zero = 1; }
		elsif($_ eq "A") { $main::ig_type = 1; }
		elsif($_ eq "C") { $main::sp_word = 1; }
		elsif($_ eq "D") { $main::proc_dirs = 1; }
		elsif($_ eq "F") { $main::fat32fix = 1; }
		elsif($_ eq "H") { $main::pad_dash = 1;	}
		elsif($_ eq "K") { $main::kill_cwords = 1; }
		elsif($_ eq "L") { $main::lc_all = 1; }
		elsif($_ eq "N") { $main::pad_digits = 1; }
		elsif($_ eq "P") { $main::kill_sp_patterns = 1; }
		elsif($_ eq "U") { $main::uc_all = 1; }

		else
		{
			&plog(0, "main: unkown short option \"$_\", cowardly refusing to run.");
			exit 0;
		}
	}
}

