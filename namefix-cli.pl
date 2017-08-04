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
use FindBin qw($Bin);

use lib		"$Bin/libs/";
use lib		"$Bin/libs/cli";
# $0 = location of scipt either full or relative, usefull to determine scripts location

# mems libs
use fixname;
use run_namefix;
use misc;
use config;
require "$Bin/libs/global_variables.pm";
use nf_print;

use dir;
use mp3;
use filter;
use undo;
use htmlh;

use cli_help;
use cli_print;

use config;

#--------------------------------------------------------------------------------------------------------------
# define global vars
#--------------------------------------------------------------------------------------------------------------

our $id3_art_str;
our $undo_cur_file;
our $id3_gen_str;
our $kill_patterns_arr;
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
# our $file_ext_2_proc;
our $front_a;
our $id3_alb_set;
our $truncate_style;
our $OVERWRITE;
our $intr_char;
our $links;
our $split_dddd;
our $kill_words_arr;
our $undo_cur;
our $trunc_char;
our $id3_force_guess_tag;
our $id3_gen_set;
our $CLI;
our $todo;
our $end_a;
our $changelog;
our $id3_year_set;
our $id3v1_rm;
our $id3_art_set;
our $LOG_STDOUT;
our $sp_char;
our $log_file;
our $undo_pre;
our $id3_com_str;
our $filter_string;
our $recr;
our $about;
our $rpwnew;
our $undo_pre_file;

our $WORD_SPECIAL_CASING;

$main::CLI = 1;

#--------------------------------------------------------------------------------------------------------------
# load config file if it exists
#--------------------------------------------------------------------------------------------------------------


if(-f $config::hash_tsv)
{
	&config::load_hash;
}

if($config::hash{ZERO_LOG}{value})
{
	&misc::clog;
}

&misc::plog(1, "**** namefix.pl $main::version start *************************************************");
&misc::plog(4, "main: \$Bin = \"$Bin\"");

$main::CLI = 1;	# set cli mode flag

#--------------------------------------------------------------------------------------------------------------
# CLI Variables
#--------------------------------------------------------------------------------------------------------------

my @tmp = ();
my $text = "";

#-------------------------------------------------------------------------------------------------------------
# 1st run check
#-------------------------------------------------------------------------------------------------------------

if(!-f $config::hash_tsv)
{
	&cli_print("No config file found, Creating.", "<MSG>");
	&config::save;
}

if(!-f $main::casing_file)
{
	&cli_print("No Special Word Casing file found, Creating.", "<MSG>");
	&misc::save_file($main::casing_file, join("\n", @main::word_casing_arr));
}

if(!-f $main::killwords_file)
{
	&cli_print("No Kill Words file found, Creating.", "<MSG>");
	&misc::save_file($main::killwords_file, join("\n", @main::kill_words_arr));
}

if(!-f $main::killpat_file)
{
	&cli_print("No Kill Patterns file found, Creating.", "<MSG>");
	&misc::save_file($main::killpat_file, join("\n", @main::kill_patterns_arr));
}

#-------------------------------------------------------------------------------------------------------------
# Startup options
#-------------------------------------------------------------------------------------------------------------

&config::load_hash;

$main::dir = $ARGV[$#ARGV];

if (!defined $main::dir)
{
	$main::dir = cwd;
}

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

$config::hash{ERROR_STDOUT}{value} = 1;

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
		&cli_help::show("help");
		exit 0;
	}
	if($_ eq "--help-short")
	{
		&cli_help::show("short");
		exit 0;
	}
	if($_ eq "--help-long")
	{
		&cli_help::show("log");
		exit 0;
	}
	if($_ eq "--help-misc")
	{
		&cli_help::show("misc");
		exit 0;
	}
	if($_ eq "--help-adv")
	{
		&cli_help::show("adv");
		exit 0;
	}
	elsif($_ eq "--help-mp3")
	{
		&cli_help::show("mp3");
		exit 0;
	}
	elsif($_ eq "--help-trunc")
	{
		&cli_help::show("trunc");
		exit 0;
	}
	elsif($_ eq "--help-enum")
	{
		&cli_help::show("enum");
		exit 0;
	}
	elsif($_ eq "--help-doc")
	{
		&cli_help::show("doc");
		exit 0;
	}
	elsif($_ eq "--help-debug")
	{
		&cli_help::show("debug");
		exit 0;
	}
	elsif($_ eq "--help-hacks")
	{
		&cli_help::show("hacks");
		exit 0;
	}

	elsif($_ eq "--help-all")
	{
		&cli_help::show("all");
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
		$config::hash{case}{value} = 1;
	}
	elsif($_ eq "--spaces")
	{
		$config::hash{spaces}{value} = 1;
	}
	elsif($_ eq "--dots")
	{
		$config::hash{dot2space}{value} = 1;
	}
	elsif($_ eq "--regexp")
	{
		 $config::hash{FILTER_REGEX}{value} = 0;
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
		$config::hash{kill_cwords}{value} = 1;
	}

	elsif($_ eq "--rm-pat")
	{
		$config::hash{kill_sp_patterns}{value} = 1;
	}
	elsif($_ eq "--case-sp")
	{
		$config::hash{WORD_SPECIAL_CASING}{value} = 1;
	}
	elsif($_ eq "--fs-fix")
	{
		$config::hash{fat32fix}{value} = 1;
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
		$main::OVERWRITE = 1;
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
		$config::hash{FILTER_REGEX}{value} = 1;
	}
	elsif(/--space-char=(.*)/ || /--spc=(.*)/)
	{
		$config::hash{space_character}{value} = $1;
	}
	elsif(/--media-types=(.*)/ || /--mt=(.*)/)
	{
		$config::hash{file_ext_2_proc}{value} = $1;
	}

	#######################
	# Truncate options
	######################

	elsif(/-trunc=(.*)/)
	{
		$main::truncate = 1;
		$config::hash{'truncate_to'}{'value'} = $1;

	}
	elsif(/--trunc-pat=(.*)/)
	{
		$config::hash{truncate_style}{value} = $1;
	}
	elsif(/--trunc-ins=(.*)/)
	{
		$config::hash{trunc_char}{value} = $1;
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
		$config::hash{enum_opt}{value} = $1;
	}
	elsif(/--enum-zero-pad=(.*)/)
	{
		$config::hash{enum_pad}{value} = 1;
		$config::hash{enum_pad_zeros}{value} = $1;
	}

	#####################
	# Misc Options
	#####################

	elsif($_ eq "--int")
	{
		$config::hash{intr_char}{value} = 1;
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
		$config::hash{uc_all}{value} = 1;
	}

	elsif($_ eq "--lc-all" || $_ eq "--lc")
	{
		$config::hash{lc_all}{value} = 1;
	}

	elsif($_ eq "--rm-nc" || $_ eq "--rmc")
	{
		$config::hash{sp_char}{value} = 1;
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
		$config::hash{HTML_HACK}{value} = 1;
	}
	elsif(/--browser=(.*)/)
	{
		$config::hash{browser}{value} = $1;
	}

	#####################
	# MP3 Options
	#####################

	elsif($_ eq "--id3-guess")
	{
		$config::hash{id3_mode}{value} = 1;
		$config::hash{id3_guess_tag}{value} = 1;
	}
	elsif($_ eq "--id3-overwrite")
	{
		$config::hash{id3_mode}{value} = 1;
		$main::id3_force_guess_tag = 1;
	}
	elsif($_ eq "--id3-rm-v1")
	{
		$config::hash{id3_mode}{value} = 1;
		$main::id3v1_rm = 1;
	}
	elsif($_ eq "--id3-rm-v2")
	{
		$config::hash{id3_mode}{value} = 1;
		$main::id3v2_rm = 1;
	}
	elsif(/--id3-art=(.*)/)
	{
		$config::hash{id3_mode}{value} = 1;
		$main::id3_art_set = 1;
		$main::id3_art_str = $1;
	}
	elsif(/--id3-tit=(.*)/)
	{
		$config::hash{id3_mode}{value} = 1;
		$main:: = $1;
	}
	elsif(/--id3-tra=(.*)/)
	{
		$config::hash{id3_mode}{value} = 1;
		$main:: = $1;
	}
	elsif(/--id3-alb=(.*)/)
	{
		$config::hash{id3_mode}{value} = 1;
		$main::id3_alb_set = 1;
		$main::id3_alb_str = $1;
	}
	elsif(/--id3-gen=(.*)/)
	{
		$config::hash{id3_mode}{value} = 1;
		$main::id3_gen_set = 1;
		$main::id3_gen_str = $1;
	}
	elsif(/--id3-yer=(.*)/)
	{
		$config::hash{id3_mode}{value} = 1;
		$main::id3_year_set = 1;
		$main::id3_year_str = $1;
	}
	elsif(/--id3-com=(.*)/)
	{
		$config::hash{id3_mode}{value} = 1;
		$main::id3_com_set = 1;
		$main::id3_com_str = $1;
	}

	##########################

	elsif(/--debug=(.*)/)
	{
		$config::hash{'debug'}{'value'} = $1;
	}
	elsif($_ eq "--debug-stdout")
	{
		$config::hash{LOG_STDOUT}{value} = 1;
	}

	#############################
	# Document options
	#############################


	elsif($_ eq "--changelog")
	{
		$text = join("", &misc::readf($main::changelog));
		print "$text\n\n";
		exit 1;
	}
	elsif($_ eq "--about")
	{
		$text = join("", &misc::readf($main::about));
		print "$text\n\n";
		exit 1;
	}
	elsif($_ eq "--todo")
	{
		$text = join("", &misc::readf($main::todo));
		print "$text\n\n";
		exit 1;
	}
	elsif($_ eq "--thanks")
	{
		$text = join("", &misc::readf($main::thanks));
		print "$text\n\n";
		exit 1;
	}
	elsif($_ eq "--links")
	{
		$text = join("", &misc::readf($main::links));
		print "$text\n\n";
		exit 1;
	}
	elsif(/--editor=(.*)/)
	{
		$config::hash{editor}{value} = $1;
	}
	elsif($_ eq "--ed-config")
	{
		system("$config::hash{editor}{value} $config::hash_tsv");
		exit 1;
	}

	elsif($_ eq "--ed-spcase")
	{
		system("$config::hash{editor}{value} $main::casing_file");
		exit 1;
	}
	elsif($_ eq "--ed-rmwords")
	{
		system("$config::hash{editor}{value} $main::killwords_file");
		exit 1;
	}
	elsif($_ eq "--ed-rmpat")
	{
		system("$config::hash{editor}{value} $main::killpat_file");
		exit 1;
	}
	elsif($_ eq "--show-log")
	{
		$text = join("", &misc::readf($main::log_file));
		print "$text\n\n";
		exit 1;
	}

	#############################
	# Save config options
	#############################

	elsif($_ eq "--save-options" || $_ eq "--save-opt" || $_ eq "--save-config")
	{
		&config::save;
		&cli_print("Options Saved, exiting", "<MSG>");
		exit 1;
	}
	else
	{
		&misc::plog(0, "main: unkown long option \"$_\", cowardly refusing to run.");
		exit 0;
	}
}


#--------------------------------------------------------------------------------------------------------------
# Main
#--------------------------------------------------------------------------------------------------------------

if(!$main::testmode && !$main::UNDO)
{
	&undo::clear;
	$main::undo_dir = $main::dir;
	&misc::save_file($main::undo_dir_file, $main::dir);
}

# set main dir, run fixname.....
print "*** Processing dir: $main::dir\n";

&misc::save_file($main::html_file, " ");	# clear html file

&htmlh::html("<table border=1>");
&htmlh::html("<TR><TD colspan=2><b>Before</b></TD><TD colspan=2><b>After</b></TD></TR>");


if($main::UNDO)
{
	@main::undo_pre = &misc::readf($main::undo_pre_file);
	@main::undo_cur = &misc::readf($main::undo_cur_file);
	@tmp = &misc::readf($main::undo_dir_file);
	$main::undo_dir = $tmp[0];
	&undo::undo_rename;
}
else
{
	&run_namefix::run;
}

&htmlh::html("</table>");

if($config::hash{HTML_HACK}{value})
{
	system("$config::hash{browser}{value} $main::html_file");
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

		elsif($_ eq "c") { $config::hash{case}{value} = 1; }
		elsif($_ eq "g") { $main::advance = 0; }
		elsif($_ eq "o") { $config::hash{dot2space}{value} = 1; }
		elsif($_ eq "p") { $config::hash{spaces}{value} = 1; }
		elsif($_ eq "s") { $main::scene = 1; }
		elsif($_ eq "u") { $main::unscene = 1; }
		elsif($_ eq "x") { $config::hash{FILTER_REGEX}{value} = 0; }

		elsif($_ eq "0") { $main::pad_digits_w_zero = 1; }
		elsif($_ eq "A") { $main::ig_type = 1; }
		elsif($_ eq "C") { $config::hash{WORD_SPECIAL_CASING}{value} = 1; }
		elsif($_ eq "D") { $main::proc_dirs = 1; }
		elsif($_ eq "F") { $config::hash{fat32fix}{value} = 1; }
		elsif($_ eq "H") { $main::pad_dash = 1;	}
		elsif($_ eq "K") { $config::hash{kill_cwords}{value} = 1; }
		elsif($_ eq "L") { $config::hash{lc_all}{value} = 1; }
		elsif($_ eq "N") { $main::pad_digits = 1; }
		elsif($_ eq "P") { $config::hash{kill_sp_patterns}{value} = 1; }
		elsif($_ eq "U") { $config::hash{uc_all}{value} = 1; }

		else
		{
			&misc::plog(0, "main: unkown short option \"$_\", cowardly refusing to run.");
			exit 0;
		}
	}
}

