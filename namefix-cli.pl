#!/usr/bin/perl -w

use strict;
use warnings;

use Data::Dumper::Concise;

use English;
use Cwd;
use Carp qw(cluck longmess shortmess);
use MP3::Tag;
use File::Find;
use File::Basename qw(&basename &dirname);

use File::Copy;
use FindBin qw($Bin);

use lib		"$Bin/libs/";
use lib		"$Bin/libs/cli";

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
# check for debug flag early
#--------------------------------------------------------------------------------------------------------------

my $debug_arg = undef;
for (my $i = 0; $i <= $#ARGV; $i++)
{
	if($ARGV[$i] =~ /^--debug=(\d+)$/)
	{
		$config::hash{'debug'}{'value'} = $1;
		$debug_arg = $1;
		last;
	}
}

#--------------------------------------------------------------------------------------------------------------
# load config file if it exists
#--------------------------------------------------------------------------------------------------------------

$config::CLI = 1;	# set cli mode flag

&config::load_hash                  if -f	$config::hash_tsv;

$config::hash{debug}{value} = $debug_arg if defined $debug_arg;

&misc::null_file($main::log_file)	if      $config::hash{zero_log}{value};

&misc::plog(2, "**** namefix.pl $config::version start *************************************************");
&misc::plog(4, "main: \$Bin = \"$Bin\"");

#--------------------------------------------------------------------------------------------------------------
# CLI Variables
#--------------------------------------------------------------------------------------------------------------

my @tmp = ();
my $text = '';

#-------------------------------------------------------------------------------------------------------------
# 1st run check
#-------------------------------------------------------------------------------------------------------------

if(!-f $config::hash_tsv)
{
	&misc::plog(1, "No config file found, Creating.");
	&config::save_hash;
}

if(!-f $config::casing_file)
{
	&misc::plog(1, "No Special Word Casing file found, Creating.");
	&misc::save_file($config::casing_file, join("\n", @config::word_casing_arr));
}

if(!-f $config::killwords_file)
{
	&misc::plog(1, "No Kill Words file found, Creating.");
	&misc::save_file($config::killwords_file, join("\n", @config::kill_words_arr));
}

if(!-f $config::killpat_file)
{
	&misc::plog(1, "No Kill Patterns file found, Creating.");
	&misc::save_file($config::killpat_file, join("\n", @config::kill_patterns_arr));
}

#-------------------------------------------------------------------------------------------------------------
# Startup options
#-------------------------------------------------------------------------------------------------------------

# Check if last argument looks like a directory/file (not an option)
if (scalar @ARGV > 0 && (-f $ARGV[$#ARGV] || -d $ARGV[$#ARGV]))
{
	if(-f $ARGV[$#ARGV])
	{
		# we will force full string match if a single file is given
		$config::hash{filter_regex}{value} 			= 1;	

		# set filter so we only process this file
		$config::hash{filter}{value}				= 1;
		$config::hash{filter_ignore_case}{value}	= 0;

		my $basename			= basename($ARGV[$#ARGV]);

		$config::filter_string	= "^" . (quotemeta $basename) . '$';
		$config::dir			= dirname($ARGV[$#ARGV]);

		&misc::plog(2, "filter_string set to '$config::filter_string'");
		&misc::plog(2, "running on single file '$ARGV[$#ARGV]'");
	}
	else
	{
		$config::dir = $ARGV[$#ARGV];
	}
	
	pop @ARGV;
	chdir $config::dir;
}
else
{
	$config::dir = cwd;
}

#--------------------------------------------------------------------------------------------------------------
# Parse Options
#--------------------------------------------------------------------------------------------------------------

$config::hash{error_stdout}{value} = 1;

if(scalar @ARGV == 0)
{
	&cli_help::show('help');
	exit;
}

for my $arg(@ARGV)
{
	# found a short option, process it
	if($arg !~ /^--/ && $arg =~ /^-/ )
	{
		&proc_short_opts($arg);
		next;
	}

	if($arg eq '--help')
	{
		&cli_help::show('help');
		exit 0;
	}

	if($arg eq '--help-short')
	{
		&cli_help::show('short');
		exit 0;
	}

	if($arg eq '--help-long')
	{
		&cli_help::show('log');
		exit 0;
	}

	if($arg eq '--help-misc')
	{
		&cli_help::show('misc');
		exit 0;
	}

	if($arg eq '--help-adv')
	{
		&cli_help::show('adv');
		exit 0;
	}

	elsif($arg eq '--help-mp3')
	{
		&cli_help::show('mp3');
		exit 0;
	}

	elsif($arg eq '--help-trunc')
	{
		&cli_help::show('trunc');
		exit 0;
	}

	elsif($arg eq '--help-enum')
	{
		&cli_help::show('enum');
		exit 0;
	}

	elsif($arg eq '--help-doc')
	{
		&cli_help::show('doc');
		exit 0;
	}

	elsif($arg eq '--help-debug')
	{
		&cli_help::show('debug');
		exit 0;
	}

	elsif($arg eq '--help-hacks')
	{
		&cli_help::show('hacks');
		exit 0;
	}

	elsif($arg eq '--help-exif')
	{
		&cli_help::show('exif');
		exit 0;
	}	

	elsif($arg eq '--help-all')
	{
		&cli_help::show('all');
		exit 0;
	}

	#####################
	# Main Options
	#####################

	elsif($arg eq '--cleanup' || $arg eq '--clean' )
	{
		$config::hash{cleanup_general}{value} = 1;
	}

	elsif($arg eq '--rename' || $arg eq '--ren')
	{
		$config::PREVIEW = 0;
	}

	elsif($arg eq '--case')
	{
		$config::hash{case}{value} = 1;
	}

	elsif($arg eq '--spaces')
	{
		$config::hash{spaces}{value} = 1;
	}

	elsif($arg eq '--dots')
	{
		$config::hash{dot2space}{value} = 1;
	}

	elsif($arg eq '--regexp')
	{
		 $config::hash{filter_regex}{value} = 0;
	}

  	elsif($arg =~ /---remove=(.*)/ || $arg =~ /--rm=(.*)/)
 	{
 		$config::hash{replace}{value} = 1;
		$config::ins_str_old = $1;
 	}

	elsif($arg =~ /--replace=(.*)/ || $arg =~ /--rp=(.*)/)
	{
		if(!$config::hash{replace}{value})
		{
			&misc::plog(0, "main: option replace present but remove option not");
			exit;
		}
		$config::ins_str = $1;
	}

	elsif($arg =~ /--append-front=(.*)/ || $arg =~ /--af=(.*)/ )
	{
		$config::hash{ins_start}{value} = 1;
		$config::ins_front_str = $1;
	}

	elsif($arg =~ /--end-front=(.*)/ || $arg =~ /--ea=(.*)/ )
	{
		$config::end_a = 1;
		$config::ins_end_str = $1;
	}
	elsif($arg eq '--rm-words')
	{
		$config::hash{kill_cwords}{value} = 1;
	}

	elsif($arg eq '--rm-pat')
	{
		$config::hash{kill_sp_patterns}{value} = 1;
	}

	elsif($arg eq '--case-sp')
	{
		$config::hash{word_special_casing}{value} = 1;
	}

	elsif($arg eq '--fs-fix')
	{
		$config::hash{fat32fix}{value} = 1;
	}

	#####################
	# Advanced Options
	#####################

	elsif($arg eq '--undo')
	{
		$config::UNDO = 1;
	}

	elsif($arg eq '--recr')
	{
		$config::hash{recursive}{value} = 1;
	}

	elsif($arg eq '--dir')
	{
		$config::hash{proc_dirs}{value} = 1;
	}

	elsif($arg eq '--overwrite')
	{
		$config::hash{overwrite}{value} = 1;
	}

 	elsif($arg eq '--all-files')
 	{
 		$config::hash{ignore_file_type}{value} = 1;
 	}

	elsif($arg =~ /--filt=(.*)/)
	{
		$config::filter_string = $1;
	}

	elsif($arg eq '--filt-regexp')
	{
		$config::hash{filter_regex}{value} = 1;
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
		$config::hash{truncate}{truncate}{value} = 1;
		$config::hash{truncate_to}{value} = $1;

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

 	elsif($arg eq '--enum')
 	{
 		$config::hash{enum}{value} = 1;
 	}

	elsif($arg =~ /--enum-style=(.*)/)
	{
		$config::hash{enum_opt}{value} = $1;
	}

 	elsif($arg eq '--enum-add-strings')
 	{
 		$config::hash{enum_add}{value} = 1;
 	}

	elsif($arg =~ /--enum-string-(front|start)=(.*)/)
	{
 		$config::hash{enum_add}{value} = 1;
		$config::enum_start_str = $2;
	}

	elsif($arg =~ /--enum-string-(end|stop)=(.*)/)
	{
 		$config::hash{enum_add}{value} = 1;
		$config::enum_end_str = $2;
	}

	elsif($arg =~ /--enum-zero-pad=(.*)/)
	{
		$config::hash{enum_pad}{value} = 1;
		$config::hash{enum_pad_zeros}{value} = $1;
	}

	#####################
	# Misc Options
	#####################

	elsif($arg eq '--int')
	{
		$config::hash{intr_char}{value} = 1;
	}

	elsif($arg eq '--7bit')
	{
		$config::hash{c7bit}{value} = 1;
	}

	elsif($arg eq '--scene' || $arg eq '--sc')
	{
		$config::hash{scene}{value} = 1;
	}

	elsif($arg eq '--unscene' || $arg eq '--usc')
	{
		$config::hash{unscene}{value} = 1;
	}

	elsif($arg eq '--uc-all' || $arg eq '--uc')
	{
		$config::hash{uc_all}{value} = 1;
	}

	elsif($arg eq '--lc-all' || $arg eq '--lc')
	{
		$config::hash{lc_all}{value} = 1;
	}

	elsif($arg eq '--rm-nc' || $arg eq '--rmc')
	{
		$config::hash{sp_char}{value} = 1;
	}

	elsif($arg eq '--rm-starting-digits' || $arg eq '--rsd')
	{
		$config::hash{digits}{value} = 1;
	}

	elsif($arg eq '--rm-all-digits' || $arg eq '--rad')
	{
		$config::hash{rm_digits}{value} = 1;
	}

	elsif($arg eq '--pad-ntonn' || $arg eq '--pn2nn')
	{
		$config::hash{pad_N_to_NN}{value} = 1;
	}

	elsif($arg eq '--pad-hyphen' || $arg eq '--ph')
	{
		$config::hash{pad_dash}{value} = 1;
	}

	elsif($arg eq '--pad-num' || $arg eq '--pn')
	{
		$config::hash{pad_digits}{value} = 1;
	}

	elsif($arg eq '--pad-num-w0' || $arg eq '--p0')
	{
		$config::hash{pad_digits_w_zero}{value} = 1;
	}

	elsif($arg eq '--pad-nnnn-wx' || $arg eq '--px')
	{
		$config::hash{split_dddd}{value} = 1;
	}

	#####################
	# Hacks Options
	#####################

	elsif($arg eq '--html')
	{
		$config::hash{html_hack}{value} = 1;
	}
	elsif($arg =~ /--browser=(.*)/)
	{
		$config::hash{browser}{value} = $1;
	}

	#####################
	# MP3 Options
	#####################

	elsif($arg eq '--id3-guess')
	{
		$config::hash{id3_mode}{value} = 1;
		$config::hash{id3_guess_tag}{value} = 1;
	}

	elsif($arg eq '--id3-overwrite')
	{
		$config::hash{id3_mode}{value} = 1;
		$config::hash{audio_force}{value} = 1;
	}

	elsif($arg eq '--id3-rm-v1')
	{
		$config::hash{id3_mode}{value} = 1;
		$config::hash{rm_audio_tags}{value} = 1;
	}

	elsif($arg eq '--id3-rm-v2')
	{
		$config::hash{id3_mode}{value} = 1;
		$config::hash{rm_audio_tags}{value} = 1;
	}

	elsif($arg =~ /--id3-art=(.*)/)
	{
		$config::hash{id3_mode}{value} = 1;
		$config::hash{audio_set_artist}{value} = 1;
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
		$config::hash{audio_set_album}{value} = 1;
		$config::id3_alb_str = $1;
	}

	elsif($arg =~ /--id3-gen=(.*)/)
	{
		$config::hash{id3_mode}{value} = 1;
		$config::hash{audio_set_genre}{value} = 1;
		$config::id3_gen_str = $1;
	}

	elsif($arg =~ /--id3-yer=(.*)/)
	{
		$config::hash{id3_mode}{value} = 1;
		$config::hash{audio_set_year}{value} = 1;
		$config::id3_year_str = $1;
	}

	elsif($arg =~ /--id3-com=(.*)/)
	{
		$config::hash{id3_mode}{value} = 1;
		$config::hash{audio_set_comment}{value} = 1;
		$config::id3_com_str = $1;
	}

	#####################
	# EXIF
	#####################

	elsif($arg eq '--exif-show')
	{
		$config::hash{exif_show}{value} = 1;
	}
	elsif($arg eq '--exif-rm')
	{
		$config::hash{exif_rm_all}{value} = 1;
	}

	#####################
	# DEBUG
	#####################

	elsif($arg =~ /^--debug=(\d+)$/)
	{
		# $config::hash{'debug'}{'value'} = $1;
		# do nothing, this was handled at start
		# this is just to avoid the unknown option error
	}

	elsif($arg eq '--debug-stdout')
	{
		$config::hash{log_stdout}{value} = 1;
	}

	#############################
	# Document options
	#############################

	elsif($arg eq '--changelog')
	{
		$text = join("", &misc::readf($config::changelog));
		print "$text\n\n";
		exit;
	}

	elsif($arg eq '--about')
	{
		$text = join("", &misc::readf($config::about));
		print "$text\n\n";
		exit;
	}

	elsif($arg eq '--todo')
	{
		$text = join("", &misc::readf($config::todo));
		print "$text\n\n";
		exit;
	}

	elsif($arg eq '--thanks')
	{
		$text = join("", &misc::readf($config::thanks));
		print "$text\n\n";
		exit;
	}

	elsif($arg eq '--links')
	{
		$text = join("", &misc::readf($config::links));
		print "$text\n\n";
		exit;
	}

	elsif($arg =~ /--editor=(.*)/)
	{
		$config::hash{editor}{value} = $1;
	}

	elsif($arg eq '--ed-config')
	{
		system("$config::hash{editor}{value} $config::hash_tsv");
		exit;
	}

	elsif($arg eq '--ed-spcase')
	{
		system("$config::hash{editor}{value} $config::casing_file");
		exit;
	}

	elsif($arg eq '--ed-rmwords')
	{
		system("$config::hash{editor}{value} $config::killwords_file");
		exit;
	}

	elsif($arg eq '--ed-rmpat')
	{
		system("$config::hash{editor}{value} $config::killpat_file");
		exit;
	}

	elsif($arg eq '--show-log')
	{
		$text = join("", &misc::readf($main::log_file));
		print "$text\n\n";
		exit;
	}

	#############################
	# Save config options
	#############################

	elsif($arg eq '--save-options' || $arg eq '--save-opt' || $arg eq '--save-config')
	{
		&config::save;
		&cli_print::print("Options Saved, exiting", "<MSG>");
		exit;
	}
	else
	{
		&quit("main: unkown long option \"$arg\", cowardly refusing to run.");
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
	@config::undo_pre	= &misc::readf($config::undo_pre_file);
	@config::undo_cur	= &misc::readf($config::undo_cur_file);
	@tmp				= &misc::readf($config::undo_dir_file);
	$config::undo_dir	= $tmp[0];
	&undo::undo_rename;
}
else
{
	&run_namefix::run;
}

&htmlh::html("</table>");

if($config::hash{html_hack}{value})
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
	return unless defined $string;  # Exit early if no string provided
	
	my @tmp = split('', $string);  # Split into individual characters

	for my $short_opt(@tmp)
	{
		if($short_opt eq "h")  # Use explicit comparison instead of bare regex
		{
			&cli_help("short");
		}

		elsif($short_opt eq "-") { next; }
		elsif($short_opt eq "!") { $config::PREVIEW								= 0; }

		elsif($short_opt eq "c") { $config::hash{case}{value}					= 1; }
		elsif($short_opt eq "g") { $config::hash{cleanup_general}{value}		= 1; }
		elsif($short_opt eq "o") { $config::hash{dot2space}{value}				= 1; }
		elsif($short_opt eq "p") { $config::hash{spaces}{value}					= 1; }
		elsif($short_opt eq "s") { $config::hash{scene}{value}					= 1; }
		elsif($short_opt eq "u") { $config::hash{unscene}{value}				= 1; }
		elsif($short_opt eq "x") { $config::hash{filter_regex}{value}			= 0; }

		elsif($short_opt eq "7") { $config::hash{c7bit}{value}					= 1; }
		elsif($short_opt eq "i") { $config::hash{intr_char}{value}				= 1; }

		elsif($short_opt eq "0") { $config::hash{pad_digits_w_zero}{value}		= 1; }
		elsif($short_opt eq "A") { $config::hash{ignore_file_type}{value}		= 1; }
		elsif($short_opt eq "C") { $config::hash{word_special_casing}{value}	= 1; }
		elsif($short_opt eq "D") { $config::hash{proc_dirs}{value}				= 1; }
		elsif($short_opt eq "F") { $config::hash{fat32fix}{value}				= 1; }
		elsif($short_opt eq "H") { $config::hash{pad_dash}{value}				= 1; }
		elsif($short_opt eq "K") { $config::hash{kill_cwords}{value}			= 1; }
		elsif($short_opt eq "L") { $config::hash{lc_all}{value}					= 1; }
		elsif($short_opt eq "N") { $config::hash{pad_digits}{value}				= 1; }
		elsif($short_opt eq "P") { $config::hash{kill_sp_patterns}{value}		= 1; }
		elsif($short_opt eq "U") { $config::hash{uc_all}{value}					= 1; }

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
