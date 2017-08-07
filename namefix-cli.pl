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

# files
our $log_file		= "$config::home/.namefix.pl/namefix-cli.pl.$config::version.log";
our $html_file		= "$config::home/.namefix.pl/namefix_html_output_hack.html";

#--------------------------------------------------------------------------------------------------------------
# load config file if it exists
#--------------------------------------------------------------------------------------------------------------


&config::load_hash	if -f	$config::hash_tsv;
&misc::clog		if	$config::hash{ZERO_LOG}{value};

&misc::plog(1, "**** namefix.pl $config::version start *************************************************");
&misc::plog(4, "main: \$Bin = \"$Bin\"");

$config::CLI = 1;	# set cli mode flag

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
	&cli_print::print("No config file found, Creating.", "<MSG>");
	&config::save;
}

if(!-f $config::casing_file)
{
	&cli_print::print("No Special Word Casing file found, Creating.", "<MSG>");
	&misc::save_file($config::casing_file, join("\n", @config::word_casing_arr));
}

if(!-f $config::killwords_file)
{
	&cli_print::print("No Kill Words file found, Creating.", "<MSG>");
	&misc::save_file($config::killwords_file, join("\n", @config::kill_words_arr));
}

if(!-f $config::killpat_file)
{
	&cli_print::print("No Kill Patterns file found, Creating.", "<MSG>");
	&misc::save_file($config::killpat_file, join("\n", @config::kill_patterns_arr));
}

#-------------------------------------------------------------------------------------------------------------
# Startup options
#-------------------------------------------------------------------------------------------------------------

&config::load_hash;

$config::dir = $ARGV[$#ARGV];

if (!defined $config::dir)
{
	$config::dir = cwd;
}

if(-d $config::dir)
{
	chdir $config::dir;
	$config::dir = cwd();

	if(!-d $config::dir)
	{
		plog(0, "main: $config::dir is not a directory, cowardly refusing to process it");
		exit 0;
	}
	else
	{
		pop @ARGV;
	}
}
else
{
	$config::dir = cwd;
}

#--------------------------------------------------------------------------------------------------------------
# Parse Options
#--------------------------------------------------------------------------------------------------------------

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
		$config::hash{CLEANUP_GENERAL}{value} = 1;
	}
	elsif($arg eq "--rename" || $arg eq "--ren")
	{
		$config::PREVIEW = 0;
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
 		$config::replace = 1;
		$config::ins_str_old = $1;
 	}
	elsif($arg =~ /--replace=(.*)/ || $arg =~ /--rp=(.*)/)
	{
		if(!$config::replace)
		{
			plog(0, "main: option replace present but remove option not");
			exit;
		}
		$config::ins_str = $1;
	}
	elsif($arg =~ /--append-front=(.*)/ || $arg =~ /--af=(.*)/ )
	{
		$config::INS_START = 1;
		$config::ins_front_str = $1;
	}
	elsif($arg =~ /--end-front=(.*)/ || $arg =~ /--ea=(.*)/ )
	{
		$config::end_a = 1;
		$config::ins_end_str = $1;
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
		$config::UNDO = 1;
	}
	elsif($arg eq "--recr")
	{
		$config::RECURSIVE = 1;
	}
	elsif($arg eq "--dir")
	{
		$config::hash{PROC_DIRS}{value} = 1;
	}
	elsif($arg eq "--overwrite")
	{
		$config::OVERWRITE = 1;
	}
 	elsif($arg eq "--all-files")
 	{
 		$config::IGNORE_FILE_TYPE = 1;
 	}
	elsif($arg =~ /--filt=(.*)/)
	{
		$config::filter_string = $1;
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
		$config::truncate = 1;
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
 		$config::enum = 1;
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
		$config::SCENE = 1;
	}

	elsif($arg eq "--unscene" || $arg eq "--usc")
	{
		$config::UNSCENE = 1;
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
		$config::digits = 1;
	}
	elsif($arg eq "--rm-all-digits" || $arg eq "--rad")
	{
		$config::RM_DIGITS = 1;
	}
	elsif($arg eq "--pad-hyphen" || $arg eq "--ph")
	{
		$config::pad_dash = 1;
	}
	elsif($arg eq "--pad-num" || $arg eq "--pn")
	{
		$config::pad_digits = 1;
	}
	elsif($arg eq "--pad-num-w0" || $arg eq "--p0")
	{
		$config::pad_digits_w_zero = 1;
	}
	elsif($arg eq "--pad-nnnn-wx" || $arg eq "--px")
	{
		$config::SPLIT_DDDD = 1;
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
		$config::AUDIO_FORCE = 1;
	}
	elsif($arg eq "--id3-rm-v1")
	{
		$config::hash{id3_mode}{value} = 1;
		$config::RM_AUDIO_TAGS = 1;
	}
	elsif($arg eq "--id3-rm-v2")
	{
		$config::hash{id3_mode}{value} = 1;
		$config::RM_AUDIO_TAGS = 1;
	}
	elsif($arg =~ /--id3-art=(.*)/)
	{
		$config::hash{id3_mode}{value} = 1;
		$config::AUDIO_SET_ARTIST = 1;
		$config::id3_art_str = $1;
	}
	elsif($arg =~ /--id3-tit=(.*)/)
	{
		$config::hash{id3_mode}{value} = 1;
		$config::id3_tit_str = $1;
	}
	elsif($arg =~ /--id3-tra=(.*)/)
	{
		$config::hash{id3_mode}{value} = 1;
		$config::id3_tra_str = $1;
	}
	elsif($arg =~ /--id3-alb=(.*)/)
	{
		$config::hash{id3_mode}{value} = 1;
		$config::AUDIO_SET_ALBUM = 1;
		$config::id3_alb_str = $1;
	}
	elsif($arg =~ /--id3-gen=(.*)/)
	{
		$config::hash{id3_mode}{value} = 1;
		$config::AUDIO_SET_GENRE = 1;
		$config::id3_gen_str = $1;
	}
	elsif($arg =~ /--id3-yer=(.*)/)
	{
		$config::hash{id3_mode}{value} = 1;
		$config::AUDIO_SET_YEAR = 1;
		$config::id3_year_str = $1;
	}
	elsif($arg =~ /--id3-com=(.*)/)
	{
		$config::hash{id3_mode}{value} = 1;
		$config::AUDIO_SET_COMMENT = 1;
		$config::id3_com_str = $1;
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
		$text = join("", &misc::readf($config::changelog));
		print "$text\n\n";
		exit;
	}
	elsif($arg eq "--about")
	{
		$text = join("", &misc::readf($config::about));
		print "$text\n\n";
		exit;
	}
	elsif($arg eq "--todo")
	{
		$text = join("", &misc::readf($config::todo));
		print "$text\n\n";
		exit;
	}
	elsif($arg eq "--thanks")
	{
		$text = join("", &misc::readf($config::thanks));
		print "$text\n\n";
		exit;
	}
	elsif($arg eq "--links")
	{
		$text = join("", &misc::readf($config::links));
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
		system("$config::hash{editor}{value} $config::casing_file");
		exit;
	}
	elsif($arg eq "--ed-rmwords")
	{
		system("$config::hash{editor}{value} $config::killwords_file");
		exit;
	}
	elsif($arg eq "--ed-rmpat")
	{
		system("$config::hash{editor}{value} $config::killpat_file");
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
		&cli_print::print("Options Saved, exiting", "<MSG>");
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

if(!$config::PREVIEW && !$config::UNDO)
{
	&undo::clear;
	$config::undo_dir = $config::dir;
	&misc::save_file($config::undo_dir_file, $config::dir);
}

# set main dir, run fixname.....
print "*** Processing dir: $config::dir\n";

&misc::null_file($html_file);	# clear html file

&htmlh::html("<table border=1>");
&htmlh::html("<TR><TD colspan=2><b>Before</b></TD><TD colspan=2><b>After</b></TD></TR>");


if($config::UNDO)
{
	@config::undo_pre = &misc::readf($config::undo_pre_file);
	@config::undo_cur = &misc::readf($config::undo_cur_file);
	@tmp = &misc::readf($config::undo_dir_file);
	$config::undo_dir = $tmp[0];
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
		elsif($short_opt eq "!") { $config::PREVIEW				= 0; }

		elsif($short_opt eq "c") { $config::hash{case}{value}			= 1; }
		elsif($short_opt eq "g") { $config::hash{CLEANUP_GENERAL}{value}	= 1; }
		elsif($short_opt eq "o") { $config::hash{dot2space}{value}		= 1; }
		elsif($short_opt eq "p") { $config::hash{spaces}{value}			= 1; }
		elsif($short_opt eq "s") { $config::SCENE = 1; }
		elsif($short_opt eq "u") { $config::UNSCENE = 1; }
		elsif($short_opt eq "x") { $config::hash{FILTER_REGEX}{value}		= 0; }

		elsif($short_opt eq "0") { $config::pad_digits_w_zero			= 1; }
		elsif($short_opt eq "A") { $config::IGNORE_FILE_TYPE			= 1; }
		elsif($short_opt eq "C") { $config::hash{WORD_SPECIAL_CASING}{value}	= 1; }
		elsif($short_opt eq "D") { $config::hash{PROC_DIRS}{value} = 1; }
		elsif($short_opt eq "F") { $config::hash{fat32fix}{value}		= 1; }
		elsif($short_opt eq "H") { $config::pad_dash				= 1; }
		elsif($short_opt eq "K") { $config::hash{kill_cwords}{value}		= 1; }
		elsif($short_opt eq "L") { $config::hash{lc_all}{value}			= 1; }
		elsif($short_opt eq "N") { $config::pad_digits				= 1; }
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
	$string = 'no quit message' if ! defined $string;
	$string .= "\n" if $string !~ /\n$/;

	cluck longmess("quit $string\n");
	CORE::exit;
}
