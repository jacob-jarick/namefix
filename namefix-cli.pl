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

use globals; # why wasnt this included before ???
use state;

#--------------------------------------------------------------------------------------------------------------
# define global vars
#--------------------------------------------------------------------------------------------------------------

# files
our $log_file		= "$globals::home/.namefix.pl/namefix-cli.pl.$globals::version.log";
our $html_file		= "$globals::home/.namefix.pl/namefix_html_output_hack.html";

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

$globals::CLI = 1;	# set cli mode flag

&config::load_hash                  if -f	$globals::hash_tsv;

&config::set_value('debug', $debug_arg) if defined $debug_arg;

&misc::null_file($main::log_file)	if      $config::hash{zero_log}{value};

&misc::plog(2, "**** namefix.pl $globals::version start *************************************************");
&misc::plog(4, "main: \$Bin = \"$Bin\"");

#--------------------------------------------------------------------------------------------------------------
# CLI Variables
#--------------------------------------------------------------------------------------------------------------

my @tmp = ();
my $text = '';

#-------------------------------------------------------------------------------------------------------------
# 1st run check
#-------------------------------------------------------------------------------------------------------------

if(!-f $globals::hash_tsv)
{
	&misc::plog(1, "No config file found, Creating.");
	&config::save_hash;
}

if(!-f $globals::casing_file)
{
	&misc::plog(1, "No Special Word Casing file found, Creating.");
	&misc::save_file($globals::casing_file, join("\n", @globals::word_casing_arr));
}

if(!-f $globals::killwords_file)
{
	&misc::plog(1, "No Kill Words file found, Creating.");
	&misc::save_file($globals::killwords_file, join("\n", @globals::kill_words_arr));
}

if(!-f $globals::killpat_file)
{
	&misc::plog(1, "No Kill Patterns file found, Creating.");
	&misc::save_file($globals::killpat_file, join("\n", @globals::kill_patterns_arr));
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
		&config::set_value('filter_regex', 1);

		# set filter so we only process this file
		&config::set_value('filter', 1);
		&config::set_value('filter_ignore_case', 0);

		my $basename			= basename($ARGV[$#ARGV]);

		&config::set_value('filter_string', "^" . (quotemeta $basename) . '$');

		$globals::dir = dirname($ARGV[$#ARGV]);

		&misc::plog(2, "filter_string set to '$config::hash{filter_string}{value}'");
		&misc::plog(2, "running on single file '$ARGV[$#ARGV]'");
	}
	else
	{
		$globals::dir = $ARGV[$#ARGV];
	}
	
	pop @ARGV;
	chdir $globals::dir;
}
else
{
	$globals::dir = cwd;
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

	elsif($arg eq '--help-deprecated')
	{
		&cli_help::show('deprecated');
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
		&config::set_value('cleanup_general', 1);
	}

	elsif($arg eq '--rename' || $arg eq '--ren' || $arg eq '--process' )
	{
		$globals::PREVIEW = 0;

		if($arg eq '--ren')
		{
			&misc::plog(1, "main: --ren is deprecated, use --rename or --process"); 
		}	
		if($arg eq '--rename')
		{
			&misc::plog(1, "main: --rename is deprecated, use --process");
		}
	}

	elsif($arg eq '--case')
	{
		&config::set_value('case', 1);
	}

	elsif($arg eq '--spaces')
	{
		&config::set_value('spaces', 1);
	}

	elsif($arg eq '--dots')
	{
		&config::set_value('dot2space', 1);
	}

	elsif($arg eq '--regexp' || $arg eq '--remove-use-regex')
	{
		&config::set_value('remove_regex', 1);

		if($arg eq '--regexp')
		{
			&misc::plog(1, "main: --regexp is deprecated, use --remove-use-regex"); 
		}
	}

  	elsif($arg =~ /--remove=(.*)/ || $arg =~ /--rm=(.*)/)
 	{
 		&config::set_value('replace', 1);
		&config::set_value('ins_str_old', $1);
 	}

	elsif($arg =~ /--replace=(.*)/ || $arg =~ /--rp=(.*)/)
	{
		if(!$config::hash{replace}{value})
		{
			&misc::plog(0, "main: option replace present but remove option not");
			exit;
		}

		&config::set_value('ins_str', $1);
	}

	elsif($arg =~ /--append-front=(.*)/ || $arg =~ /--af=(.*)/ )
	{
		&config::set_value('ins_start', 1);
		&config::set_value('ins_front_str', $1);
	}

	elsif($arg =~ /--append-end=(.*)/ || $arg =~ /--ae=(.*)/ )
	{
		&config::set_value('ins_end', 1);
		&config::set_value('ins_end_str', $1);
	}
	elsif($arg eq '--rm-words')
	{
		&config::set_value('kill_cwords', 1);
	}

	elsif($arg eq '--rm-pat')
	{
		&config::set_value('kill_sp_patterns', 1);
	}

	elsif($arg eq '--case-sp')
	{
		&config::set_value('word_special_casing', 1);
	}

	elsif($arg eq '--fs-fix')
	{
		&config::set_value('fat32fix', 1);
	}

	#####################
	# Advanced Options
	#####################

	elsif($arg eq '--undo')
	{
		$globals::UNDO = 1;
	}

	elsif($arg eq '--recr')
	{
		&config::set_value('recursive', 1);
	}

	elsif($arg eq '--dir')
	{
		&config::set_value('proc_dirs', 1);
	}

	elsif($arg eq '--overwrite')
	{
		&config::set_value('overwrite', 1);
	}

 	elsif($arg eq '--all-files')
 	{
 		&config::set_value('ignore_file_type', 1);
 	}

	elsif($arg =~ /--filt=(.*)/)
	{
		$config::hash{filter_string}{value} = $1;
	}

	elsif($arg eq '--filt-regexp')
	{
		&config::set_value('filter_regex', 1);
	}

	elsif($arg =~ /--space-char=(.*)/ || $arg =~ /--spc=(.*)/)
	{
		&config::set_value('space_character', $1);
	}

	elsif($arg =~ /--media-types=(.*)/ || $arg =~ /--mt=(.*)/)
	{
		&config::set_value('file_ext_2_proc', $1);
	}

	#######################
	# Truncate options
	######################

	elsif($arg =~ /--trunc=(.*)/)
	{
		&config::set_value('truncate', 1);
		&config::set_value('truncate_to', $1);

	}

	elsif($arg =~ /--trunc-pat=(.*)/)
	{
		&config::set_value('truncate_style', $1);
	}

	elsif($arg =~ /--trunc-ins=(.*)/)
	{
		&config::set_value('trunc_char', $1);
	}

	########################
	# Enumerate Options
	########################

 	elsif($arg eq '--enum')
 	{
 		&config::set_value('enum', 1);
 	}

	elsif($arg =~ /--enum-style=(.*)/)
	{
		&config::set_value('enum_opt', $1);
	}

 	elsif($arg eq '--enum-add-strings')
 	{
 		&config::set_value('enum_add', 1);
 	}

	elsif($arg =~ /--enum-string-(front|start)=(.*)/)
	{
 		&config::set_value('enum_add', 1);
		&config::set_value('enum_start_str', $2);
	}

	elsif($arg =~ /--enum-string-(end|stop)=(.*)/)
	{
 		&config::set_value('enum_add', 1);
		&config::set_value('enum_end_str', $2);
	}

	elsif($arg =~ /--enum-zero-pad=(.*)/)
	{
		&config::set_value('enum_pad', 1);
		&config::set_value('enum_pad_zeros', $1);
	}

	#####################
	# Misc Options
	#####################

	elsif($arg eq '--int')
	{
		&config::set_value('intr_char', 1);
	}

	elsif($arg eq '--7bit')
	{
		&config::set_value('c7bit', 1);
	}

	elsif($arg eq '--scene' || $arg eq '--sc')
	{
		&config::set_value('scene', 1);
	}

	elsif($arg eq '--unscene' || $arg eq '--usc')
	{
		&config::set_value('unscene', 1);
	}

	elsif($arg eq '--uc-all' || $arg eq '--uc')
	{
		&config::set_value('uc_all', 1);
	}

	elsif($arg eq '--lc-all' || $arg eq '--lc')
	{
		&config::set_value('lc_all', 1);
	}

	elsif($arg eq '--rm-nc' || $arg eq '--rmc')
	{
		&config::set_value('sp_char', 1);
	}

	elsif($arg eq '--rm-starting-digits' || $arg eq '--rsd')
	{
		&config::set_value('digits', 1);
	}

	elsif($arg eq '--rm-all-digits' || $arg eq '--rad')
	{
		&config::set_value('rm_digits', 1);
	}

	elsif($arg eq '--pad-ntonn' || $arg eq '--pn2nn')
	{
		&config::set_value('pad_N_to_NN', 1);
	}

	elsif($arg eq '--pad-hyphen' || $arg eq '--ph')
	{
		&config::set_value('pad_dash', 1);
	}

	elsif($arg eq '--pad-num' || $arg eq '--pn')
	{
		&config::set_value('pad_digits', 1);
	}

	elsif($arg eq '--pad-num-w0' || $arg eq '--p0')
	{
		&config::set_value('pad_digits_w_zero', 1);
	}

	elsif($arg eq '--pad-nnnn-wx' || $arg eq '--px')
	{
		&config::set_value('split_dddd', 1);
	}

	#####################
	# Hacks Options
	#####################

	elsif($arg eq '--html')
	{
		&config::set_value('html_hack', 1);
	}
	elsif($arg =~ /--browser=(.*)/)
	{
		&config::set_value('browser', $1);
	}

	#####################
	# MP3 Options
	#####################

	elsif($arg eq '--id3-guess')
	{
		&config::set_value('id3_mode', 1);
		&config::set_value('id3_guess_tag', 1);
	}

	elsif($arg eq '--id3-overwrite')
	{
		&config::set_value('id3_mode', 1);
		&config::set_value('id3_force', 1);
	}

	elsif($arg eq '--id3-rm-v1')
	{
		&config::set_value('id3_mode', 1);
		&config::set_value('id3_tags_rm', 1);
	}

	elsif($arg eq '--id3-rm-v2')
	{
		&config::set_value('id3_mode', 1);
		&config::set_value('id3_tags_rm', 1);
	}

	elsif($arg =~ /--id3-art=(.*)/)
	{
		&config::set_value('id3_mode', 1);
		&config::set_value('id3_set_artist', 1);
		&config::set_value('id3_art_str', $1);
	}

	elsif($arg =~ /--id3-tit=(.*)/)
	{
		&config::set_value('id3_mode', 1);
		&config::set_value('id3_tit_str', $1);
	}

	elsif($arg =~ /--id3-tra=(.*)/)
	{
		&quit("main: --id3-tra value must a number or '', you set '$1'") if $1 !~ /^(\d+|)$/;
		&config::set_value('id3_mode', 1);
		&config::set_value('id3_tra_str', $1);
	}

	elsif($arg =~ /--id3-alb=(.*)/)
	{
		&config::set_value('id3_mode', 1);
		&config::set_value('id3_set_album', 1);
		&config::set_value('id3_alb_str', $1);
	}

	elsif($arg =~ /--id3-gen=(.*)/)
	{
		&config::set_value('id3_mode', 1);
		&config::set_value('id3_set_genre', 1);
		&config::set_value('id3_gen_str', $1);
	}

	elsif($arg =~ /--id3-yer=(.*)/)
	{
		&quit("main: --id3-yer value must 4 digits or '', you set '$1'") if $1 !~ /^(\d{4}|)$/;

		&config::set_value('id3_mode', 1);
		&config::set_value('id3_set_year', 1);
		&config::set_value('id3_year_str', $1);
	}

	elsif($arg =~ /--id3-com=(.*)/)
	{
		&config::set_value('id3_mode', 1);
		&config::set_value('id3_set_comment', 1);
		&config::set_value('id3_com_str', $1);
	}

	elsif($arg eq '--id3-fn-from-tag')
	{
		&config::set_value('id3_guess_tag', 0);		# disable conflicting option

		&config::set_value('id3_fn_from_tag', 1);	# enable main option
	}

	elsif($arg =~ /--id3-fn-style=(\d+)/)
	{
		if($1 > 3)
		{
			&quit("main: --id3-fn-style value must be between 0 and 3");
		}

		&config::set_value('id3_fn_style', $1);
	}	

	#####################
	# EXIF
	#####################

	elsif($arg eq '--exif-show')
	{
		&config::set_value('exif_show', 1);
	}
	elsif($arg eq '--exif-rm')
	{
		&config::set_value('exif_rm_all', 1);
	}

	#####################
	# DEBUG
	#####################

	elsif($arg eq '--exit-on-error')
	{
		&config::set_value('exit_on_error', 1);
	}

	elsif($arg =~ /^--debug=(\d+)$/)
	{
		# $config::hash{'debug'}{'value'} = $1;
		# do nothing, this was handled at start
		# this is just to avoid the unknown option error
	}

	elsif($arg eq '--debug-stdout')
	{
		&config::set_value('log_stdout', 1);
	}

	#############################
	# Document options
	#############################

	elsif($arg eq '--changelog')
	{
		$text = join("", &misc::readf($globals::changelog));
		print "$text\n\n";
		exit;
	}

	elsif($arg eq '--about')
	{
		$text = join("", &misc::readf($globals::about));
		print "$text\n\n";
		exit;
	}

	elsif($arg eq '--todo')
	{
		$text = join("", &misc::readf($globals::todo));
		print "$text\n\n";
		exit;
	}

	elsif($arg eq '--thanks')
	{
		$text = join("", &misc::readf($globals::thanks));
		print "$text\n\n";
		exit;
	}

	elsif($arg eq '--links')
	{
		$text = join("", &misc::readf($globals::links));
		print "$text\n\n";
		exit;
	}

	elsif($arg =~ /--editor=(.*)/)
	{
		$config::hash{editor}{value} = $1;
	}

	elsif($arg eq '--ed-config')
	{
		system("$config::hash{editor}{value} $globals::hash_tsv");
		exit;
	}

	elsif($arg eq '--ed-spcase')
	{
		system("$config::hash{editor}{value} $globals::casing_file");
		exit;
	}

	elsif($arg eq '--ed-rmwords')
	{
		system("$config::hash{editor}{value} $globals::killwords_file");
		exit;
	}

	elsif($arg eq '--ed-rmpat')
	{
		system("$config::hash{editor}{value} $globals::killpat_file");
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
		&config::save_hash;
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

# when below conditions are met, we are doing a rename operation, so we need to setup undo
# record current dir to undo_dir_file
# clear undo pre/cur files
if(!$globals::PREVIEW && !$globals::UNDO)
{
	&undo::clear;
	$globals::undo_dir = $globals::dir;
	&misc::save_file($globals::undo_dir_file, $globals::dir);
}

# set main dir, run fixname.....
print "*** Processing dir: $globals::dir\n";

&misc::null_file($html_file);	# clear html file

&htmlh::html("<table border=1>");
&htmlh::html("<TR><TD colspan=2><b>Before</b></TD><TD colspan=2><b>After</b></TD></TR>");

if($globals::UNDO)
{
	@config::undo_pre	= &misc::readf($globals::undo_pre_file);
	@config::undo_cur	= &misc::readf($globals::undo_cur_file);
	@tmp				= &misc::readf($globals::undo_dir_file);
	$globals::undo_dir	= $tmp[0];
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
		elsif($short_opt eq "!") { $globals::PREVIEW							= 0; }

		elsif($short_opt eq "c") { &config::set_value('case',				1); }
		elsif($short_opt eq "g") { &config::set_value('cleanup_general',	1); }
		elsif($short_opt eq "o") { &config::set_value('dot2space',			1); }
		elsif($short_opt eq "p") { &config::set_value('spaces',				1); }
		elsif($short_opt eq "s") { &config::set_value('scene',				1); }
		elsif($short_opt eq "u") { &config::set_value('unscene',			1); }
		elsif($short_opt eq "x") { &config::set_value('filter_regex',		1); }

		elsif($short_opt eq "7") { &config::set_value('c7bit',				1); }
		elsif($short_opt eq "i") { &config::set_value('intr_char',			1); }

		elsif($short_opt eq "0") { &config::set_value('pad_digits_w_zero',		1); }
		elsif($short_opt eq "A") { &config::set_value('ignore_file_type',		1); }
		elsif($short_opt eq "C") { &config::set_value('word_special_casing',	1); }
		elsif($short_opt eq "E") { &config::set_value('proc_ext',				1); }
		elsif($short_opt eq "D") { &config::set_value('proc_dirs',				1); }
		elsif($short_opt eq "F") { &config::set_value('fat32fix',				1); }
		elsif($short_opt eq "H") { &config::set_value('pad_dash',				1); }
		elsif($short_opt eq "K") { &config::set_value('kill_cwords',			1); }
		elsif($short_opt eq "L") { &config::set_value('lc_all',					1); }
		elsif($short_opt eq "N") { &config::set_value('pad_digits',				1); }
		elsif($short_opt eq "P") { &config::set_value('kill_sp_patterns',		1); }
		elsif($short_opt eq "U") { &config::set_value('uc_all',					1); }

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
