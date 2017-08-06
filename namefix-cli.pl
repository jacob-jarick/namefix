#!/usr/bin/perl -w

use strict;
use warnings;

use English;
use Cwd;
use Carp qw(cluck longmess shortmess);
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

for my $arg(@ARGV)
{
	# found a short option, process it
	if($arg !~ /^--/ && $arg =~ /^-/ )
	{
		&proc_short_opts($arg);
		next;
	}

	if($arg eq "--help")
	{
		&cli_help::show("help");
		exit 0;
	}
	if($arg eq "--help-short")
	{
		&cli_help::show("short");
		exit 0;
	}
	if($arg eq "--help-long")
	{
		&cli_help::show("log");
		exit 0;
	}
	if($arg eq "--help-misc")
	{
		&cli_help::show("misc");
		exit 0;
	}
	if($arg eq "--help-adv")
	{
		&cli_help::show("adv");
		exit 0;
	}
	elsif($arg eq "--help-mp3")
	{
		&cli_help::show("mp3");
		exit 0;
	}
	elsif($arg eq "--help-trunc")
	{
		&cli_help::show("trunc");
		exit 0;
	}
	elsif($arg eq "--help-enum")
	{
		&cli_help::show("enum");
		exit 0;
	}
	elsif($arg eq "--help-doc")
	{
		&cli_help::show("doc");
		exit 0;
	}
	elsif($arg eq "--help-debug")
	{
		&cli_help::show("debug");
		exit 0;
	}
	elsif($arg eq "--help-hacks")
	{
		&cli_help::show("hacks");
		exit 0;
	}

	elsif($arg eq "--help-all")
	{
		&cli_help::show("all");
		exit 0;
	}

	#####################
	# Main Options
	#####################

	elsif($arg eq "--cleanup" || $arg eq "--clean" )
	{
		$main::advance = 0;
	}
	elsif($arg eq "--rename" || $arg eq "--ren")
	{
		$main::testmode = 0;
	}
	elsif($arg eq "--case")
	{
		$config::hash{case}{value} = 1;
	}
	elsif($arg eq "--spaces")
	{
		$config::hash{spaces}{value} = 1;
	}
	elsif($arg eq "--dots")
	{
		$config::hash{dot2space}{value} = 1;
	}
	elsif($arg eq "--regexp")
	{
		 $config::hash{FILTER_REGEX}{value} = 0;
	}
  	elsif($arg =~ /---remove=(.*)/ || $arg =~ /--rm=(.*)/)
 	{
 		$main::replace = 1;
		$main::rpwold = $1;
 	}
	elsif($arg =~ /--replace=(.*)/ || $arg =~ /--rp=(.*)/)
	{
		if(!$main::replace)
		{
			plog(0, "main: option replace present but remove option not");
			exit;
		}
		$main::rpwnew = $1;
	}
	elsif($arg =~ /--append-front=(.*)/ || $arg =~ /--af=(.*)/ )
	{
		$main::front_a = 1;
		$main::faw = $1;
	}
	elsif($arg =~ /--end-front=(.*)/ || $arg =~ /--ea=(.*)/ )
	{
		$main::end_a = 1;
		$main::eaw = $1;
	}
	elsif($arg eq "--rm-words")
	{
		$config::hash{kill_cwords}{value} = 1;
	}

	elsif($arg eq "--rm-pat")
	{
		$config::hash{kill_sp_patterns}{value} = 1;
	}
	elsif($arg eq "--case-sp")
	{
		$config::hash{WORD_SPECIAL_CASING}{value} = 1;
	}
	elsif($arg eq "--fs-fix")
	{
		$config::hash{fat32fix}{value} = 1;
	}

	#####################
	# Advanced Options
	#####################

	elsif($arg eq "--undo")
	{
		$main::UNDO = 1;
	}
	elsif($arg eq "--recr")
	{
		$main::recr = 1;
	}
	elsif($arg eq "--dir")
	{
		$main::proc_dirs = 1;
	}
	elsif($arg eq "--overwrite")
	{
		$main::OVERWRITE = 1;
	}
 	elsif($arg eq "--all-files")
 	{
 		$main::ig_type = 1;
 	}
	elsif($arg =~ /--filt=(.*)/)
	{
		$main::filter_string = $1;
	}
	elsif($arg eq "--filt-regexp")
	{
		$config::hash{FILTER_REGEX}{value} = 1;
	}
	elsif($arg =~ /--space-char=(.*)/ || $arg =~ /--spc=(.*)/)
	{
		$config::hash{space_character}{value} = $1;
	}
	elsif($arg =~ /--media-types=(.*)/ || $arg =~ /--mt=(.*)/)
	{
		$config::hash{file_ext_2_proc}{value} = $1;
	}

	#######################
	# Truncate options
	######################

	elsif($arg =~ /-trunc=(.*)/)
	{
		$main::truncate = 1;
		$config::hash{'truncate_to'}{'value'} = $1;

	}
	elsif($arg =~ /--trunc-pat=(.*)/)
	{
		$config::hash{truncate_style}{value} = $1;
	}
	elsif($arg =~ /--trunc-ins=(.*)/)
	{
		$config::hash{trunc_char}{value} = $1;
	}

	########################
	# Enumerate Options
	########################

 	elsif($arg eq "--enum")
 	{
 		$main::enum = 1;
 	}
	elsif($arg =~ /--enum-style=(.*)/)
	{
		$config::hash{enum_opt}{value} = $1;
	}
	elsif($arg =~ /--enum-zero-pad=(.*)/)
	{
		$config::hash{enum_pad}{value} = 1;
		$config::hash{enum_pad_zeros}{value} = $1;
	}

	#####################
	# Misc Options
	#####################

	elsif($arg eq "--int")
	{
		$config::hash{intr_char}{value} = 1;
	}

	elsif($arg eq "--scene" || $arg eq "--sc")
	{
		$main::scene = 1;
	}

	elsif($arg eq "--unscene" || $arg eq "--usc")
	{
		$main::unscene = 1;
	}

	elsif($arg eq "--uc-all" || $arg eq "--uc")
	{
		$config::hash{uc_all}{value} = 1;
	}

	elsif($arg eq "--lc-all" || $arg eq "--lc")
	{
		$config::hash{lc_all}{value} = 1;
	}

	elsif($arg eq "--rm-nc" || $arg eq "--rmc")
	{
		$config::hash{sp_char}{value} = 1;
	}
	elsif($arg eq "--rm-starting-digits" || $arg eq "--rsd")
	{
		$main::digits = 1;
	}
	elsif($arg eq "--rm-all-digits" || $arg eq "--rad")
	{
		$main::rm_digits = 1;
	}
	elsif($arg eq "--pad-hyphen" || $arg eq "--ph")
	{
		$main::pad_dash = 1;
	}
	elsif($arg eq "--pad-num" || $arg eq "--pn")
	{
		$main::pad_digits = 1;
	}
	elsif($arg eq "--pad-num-w0" || $arg eq "--p0")
	{
		$main::pad_digits_w_zero = 1;
	}
	elsif($arg eq "--pad-nnnn-wx" || $arg eq "--px")
	{
		$main::split_dddd = 1;
	}

	#####################
	# Hacks Options
	#####################

	elsif($arg eq "--html")
	{
		$config::hash{HTML_HACK}{value} = 1;
	}
	elsif($arg =~ /--browser=(.*)/)
	{
		$config::hash{browser}{value} = $1;
	}

	#####################
	# MP3 Options
	#####################

	elsif($arg eq "--id3-guess")
	{
		$config::hash{id3_mode}{value} = 1;
		$config::hash{id3_guess_tag}{value} = 1;
	}
	elsif($arg eq "--id3-overwrite")
	{
		$config::hash{id3_mode}{value} = 1;
		$main::id3_force_guess_tag = 1;
	}
	elsif($arg eq "--id3-rm-v1")
	{
		$config::hash{id3_mode}{value} = 1;
		$main::id3v1_rm = 1;
	}
	elsif($arg eq "--id3-rm-v2")
	{
		$config::hash{id3_mode}{value} = 1;
		$main::id3v2_rm = 1;
	}
	elsif($arg =~ /--id3-art=(.*)/)
	{
		$config::hash{id3_mode}{value} = 1;
		$main::id3_art_set = 1;
		$main::id3_art_str = $1;
	}
	elsif($arg =~ /--id3-tit=(.*)/)
	{
		$config::hash{id3_mode}{value} = 1;
		$main:: = $1;
	}
	elsif($arg =~ /--id3-tra=(.*)/)
	{
		$config::hash{id3_mode}{value} = 1;
		$main:: = $1;
	}
	elsif($arg =~ /--id3-alb=(.*)/)
	{
		$config::hash{id3_mode}{value} = 1;
		$main::id3_alb_set = 1;
		$main::id3_alb_str = $1;
	}
	elsif($arg =~ /--id3-gen=(.*)/)
	{
		$config::hash{id3_mode}{value} = 1;
		$main::id3_gen_set = 1;
		$main::id3_gen_str = $1;
	}
	elsif($arg =~ /--id3-yer=(.*)/)
	{
		$config::hash{id3_mode}{value} = 1;
		$main::id3_year_set = 1;
		$main::id3_year_str = $1;
	}
	elsif($arg =~ /--id3-com=(.*)/)
	{
		$config::hash{id3_mode}{value} = 1;
		$main::id3_com_set = 1;
		$main::id3_com_str = $1;
	}

	##########################

	elsif($arg =~ /--debug=(.*)/)
	{
		$config::hash{'debug'}{'value'} = $1;
	}
	elsif($arg eq "--debug-stdout")
	{
		$config::hash{LOG_STDOUT}{value} = 1;
	}

	#############################
	# Document options
	#############################


	elsif($arg eq "--changelog")
	{
		$text = join("", &misc::readf($main::changelog));
		print "$text\n\n";
		exit;
	}
	elsif($arg eq "--about")
	{
		$text = join("", &misc::readf($main::about));
		print "$text\n\n";
		exit;
	}
	elsif($arg eq "--todo")
	{
		$text = join("", &misc::readf($main::todo));
		print "$text\n\n";
		exit;
	}
	elsif($arg eq "--thanks")
	{
		$text = join("", &misc::readf($main::thanks));
		print "$text\n\n";
		exit;
	}
	elsif($arg eq "--links")
	{
		$text = join("", &misc::readf($main::links));
		print "$text\n\n";
		exit;
	}
	elsif($arg =~ /--editor=(.*)/)
	{
		$config::hash{editor}{value} = $1;
	}
	elsif($arg eq "--ed-config")
	{
		system("$config::hash{editor}{value} $config::hash_tsv");
		exit;
	}

	elsif($arg eq "--ed-spcase")
	{
		system("$config::hash{editor}{value} $main::casing_file");
		exit;
	}
	elsif($arg eq "--ed-rmwords")
	{
		system("$config::hash{editor}{value} $main::killwords_file");
		exit;
	}
	elsif($arg eq "--ed-rmpat")
	{
		system("$config::hash{editor}{value} $main::killpat_file");
		exit;
	}
	elsif($arg eq "--show-log")
	{
		$text = join("", &misc::readf($main::log_file));
		print "$text\n\n";
		exit;
	}

	#############################
	# Save config options
	#############################

	elsif($arg eq "--save-options" || $_ eq "--save-opt" || $_ eq "--save-config")
	{
		&config::save;
		&cli_print("Options Saved, exiting", "<MSG>");
		exit;
	}
	else
	{
		&quit("main: unkown long option \"$_\", cowardly refusing to run.");
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

exit;

#--------------------------------------------------------------------------------------------------------------
# End
#--------------------------------------------------------------------------------------------------------------

sub proc_short_opts
{
	my $string = shift;
	my @tmp = split(undef, $string);

	for my $short_opt(@tmp)
	{
		if(/h/)
		{
			&cli_help("short");
		}
		elsif($short_opt eq "-") { next; }
		elsif($short_opt eq "!") { $main::testmode				= 0; }

		elsif($short_opt eq "c") { $config::hash{case}{value}			= 1; }
		elsif($short_opt eq "g") { $main::advance = 0; }
		elsif($short_opt eq "o") { $config::hash{dot2space}{value}		= 1; }
		elsif($short_opt eq "p") { $config::hash{spaces}{value}			= 1; }
		elsif($short_opt eq "s") { $main::scene = 1; }
		elsif($short_opt eq "u") { $main::unscene = 1; }
		elsif($short_opt eq "x") { $config::hash{FILTER_REGEX}{value}		= 0; }

		elsif($short_opt eq "0") { $main::pad_digits_w_zero			= 1; }
		elsif($short_opt eq "A") { $main::ig_type				= 1; }
		elsif($short_opt eq "C") { $config::hash{WORD_SPECIAL_CASING}{value}	= 1; }
		elsif($short_opt eq "D") { $main::proc_dirs = 1; }
		elsif($short_opt eq "F") { $config::hash{fat32fix}{value}		= 1; }
		elsif($short_opt eq "H") { $main::pad_dash				= 1; }
		elsif($short_opt eq "K") { $config::hash{kill_cwords}{value}		= 1; }
		elsif($short_opt eq "L") { $config::hash{lc_all}{value}			= 1; }
		elsif($short_opt eq "N") { $main::pad_digits				= 1; }
		elsif($short_opt eq "P") { $config::hash{kill_sp_patterns}{value}	= 1; }
		elsif($short_opt eq "U") { $config::hash{uc_all}{value}			= 1; }

		else
		{
			&misc::plog(0, "main: unkown short option \"$short_opt\", cowardly refusing to run.");
			exit 0;
		}
	}
}

sub quit
{
	my $string = shift;

	$string .= "\n" if $string !~ /\n$/;

	cluck longmess("quit $string\n");
	exit;
	CORE::exit;
}