package config;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;
use Cwd;
use Data::Dumper::Concise;
use FindBin qw($Bin);

our %hash				= ();

require misc;
require globals;

# -----------------------------------------------------------------------------

&config_init_value('exit_on_error',		0, 0, 'bool', 'base');
&config_init_value('debug',				0, 0, 'int', 'base');
&config_init_value('log_stdout',		0, 0, 'bool', 'base');
&config_init_value('error_stdout',		1, 1, 'bool', 'base');
&config_init_value('error_notify',		1, 1, 'bool', 'base');
&config_init_value('zero_log',			1, 1, 'bool', 'base');

# -----------------------------------------------------------------------------
# MAIN TAB

&config_init_value('cleanup_general',		0, 0, 'bool', 'extended');
&config_init_value('case',					0, 0, 'bool', 'extended');
&config_init_value('word_special_casing',	0, 0, 'bool', 'extended');
&config_init_value('spaces',				0, 0, 'bool', 'extended');
&config_init_value('dot2space',				0, 0, 'bool', 'extended');
&config_init_value('kill_cwords',			0, 0, 'bool', 'extended');
&config_init_value('kill_sp_patterns',		0, 0, 'bool', 'extended');
&config_init_value('replace',				0, 0, 'bool', 'no');
&config_init_value('ins_end',				0, 0, 'bool', 'no');
&config_init_value('ins_start',				0, 0, 'bool', 'no');

# String variables for remove/replace/append operations (never saved)

&config_init_value('ins_str_old',	'', '', 'str', 'no');
&config_init_value('ins_str',		'', '', 'str', 'no');
&config_init_value('ins_front_str',	'', '', 'str', 'no');
&config_init_value('ins_end_str',	'', '', 'str', 'no');

# ID3 tag string variables (never saved)

# its metal just to select a genre so combo box isnt blank
&config_init_value('id3_gen_str',	'Metal',	'Metal',	'str', 'no');	
# the rest of these are blank
&config_init_value('id3_art_str',	'',			'',			'str', 'no');
&config_init_value('id3_alb_str',	'',			'',			'str', 'no');
&config_init_value('id3_tra_str',	'',			'',			'str', 'no');
&config_init_value('id3_tit_str',	'',			'',			'str', 'no');
&config_init_value('id3_year_str',	'',			'',			'str', 'no');
&config_init_value('id3_com_str',	'',			'',			'str', 'no');

&config_init_value('id3_fn_from_tag',	0, 0, 'bool',	'no'); # --id3-fn-from-tag
&config_init_value('id3_fn_style', 		0, 0, 'int',	'no'); # --id3-fn-style

# -----------------------------------------------------------------------------
# Legacy GUI variable - kept for compatibility but also in hash
# TODO these should no longer be referenced, check and remove

&config_init_value('end_a', 0, 0, 'bool', 'no'); # shouldnt this be ins_end

# -----------------------------------------------------------------------------
# MP3 TAB

&config_init_value('id3_mode',			0, 0, 'bool', 'extended');
&config_init_value('id3_guess_tag',		0, 0, 'bool', 'extended');
&config_init_value('id3_force',			0, 0, 'bool', 'extended');
&config_init_value('id3_tags_rm',		0, 0, 'bool', 'no');
&config_init_value('id3_set_artist',	0, 0, 'bool', 'no');
&config_init_value('id3_set_album',		0, 0, 'bool', 'no');
&config_init_value('id3_set_genre',		0, 0, 'bool', 'no');
&config_init_value('id3_set_year',		0, 0, 'bool', 'no');
&config_init_value('id3_set_comment',	0, 0, 'bool', 'no');

# -----------------------------------------------------------------------------
# MISC TAB

&config_init_value('uc_all',			0, 0, 'bool', 'extended');
&config_init_value('lc_all',			0, 0, 'bool', 'extended');
&config_init_value('intr_char',			0, 0, 'bool', 'extended');
&config_init_value('c7bit',				0, 0, 'bool', 'extended');
&config_init_value('sp_char',			0, 0, 'bool', 'extended');
&config_init_value('rm_digits',			0, 0, 'bool', 'extended');	# RM ^Digits
&config_init_value('digits',			0, 0, 'bool', 'extended');
&config_init_value('unscene',			0, 0, 'bool', 'extended');
&config_init_value('scene',				0, 0, 'bool', 'extended');
&config_init_value('pad_N_to_NN',		0, 0, 'bool', 'extended');
&config_init_value('pad_dash',			0, 0, 'bool', 'extended');
&config_init_value('pad_digits',		0, 0, 'bool', 'extended');
&config_init_value('pad_digits_w_zero', 0, 0, 'bool', 'extended');
&config_init_value('split_dddd',		0, 0, 'bool', 'extended');

# -----------------------------------------------------------------------------
# ENUMURATE TAB

&config_init_value('enum',				0,	0,	'bool',	'extended');
&config_init_value('enum_opt',			0,	0,	'bool',	'extended');
&config_init_value('enum_add',			0,	0,	'bool',	'extended');
&config_init_value('enum_pad',			0,	0,	'bool',	'extended');
&config_init_value('enum_pad_zeros',	4,	4,	'int',	'extended');
&config_init_value('enum_start_str',	'',	'',	'str',	'no');
&config_init_value('enum_end_str',		'',	'',	'str',	'no');

# -----------------------------------------------------------------------------
# TRUNCATE TAB

&config_init_value('truncate',			0,		0,		'bool',	'extended');
&config_init_value('truncate_to',		256,	256,	'int',	'extended');
&config_init_value('truncate_style',	0,		0,		'int',	'extended');
&config_init_value('trunc_char',		'',		'',		'str',	'extended');

# -----------------------------------------------------------------------------
# EXIF TAB

&config_init_value('exif_show',		0, 0, 'bool', 'extended');
&config_init_value('exif_rm_all',	0, 0, 'bool', 'extended');

# -----------------------------------------------------------------------------
# FILTER BAR

&config_init_value('filter',				0,		0,	'bool',	'extended');
&config_init_value('filter_ignore_case',	0,		0,	'bool',	'extended');
&config_init_value('filter_string',			'',		'',	'str',	'no');

# -----------------------------------------------------------------------------
# bottom menu bar

&config_init_value('recursive',			0,	0,	'bool',	'base');
&config_init_value('ignore_file_type',	0,	0,	'bool',	'extended');
&config_init_value('proc_dirs',			0,	0,	'bool',	'extended');

# -----------------------------------------------------------------------------
# CLI ONLY OPTIONS

&config_init_value('html_hack',			0,			0,			'bool',	'base');
&config_init_value('browser',			'elinks',	'elinks',	'str',	'base');
&config_init_value('editor',			'vim', 		'vim',		'str',	'base');

# This two options are not in the GUI but needed for CLI
# in the GUI the sub is triggered by a button

&config_init_value('undo',			0, 0, 'bool', 'base');
&config_init_value('save_options',	0, 0, 'bool', 'base');

# -----------------------------------------------------------------------------
# CONFIG DIALOG - MAIN TAB

&config_init_value('space_character',	' ',	' ',	'str',	'base');
&config_init_value('max_fn_length',		256,	256,	'int',	'base');
&config_init_value('save_window_size',	0,		0,		'bool',	'base');
&config_init_value('window_g',			'',		'',		'str',	'geometry');

our $save_extended			= 0;	# save main window options

# -----------------------------------------------------------------------------
# CONFIG DIALOG - ADVANCED TAB

# fat32fix - conditional default based on OS

if(lc $^O eq 'mswin32')
{
	&config_init_value('fat32fix', 0, 0, 'bool', 'base');
}
else
{
	&config_init_value('fat32fix', 1, 1, 'bool', 'base');
}

&config_init_value('filter_regex',	0, 0, 'bool', 'base');
&config_init_value('overwrite',		0, 0, 'bool', 'base');
&config_init_value('remove_regex',	0, 0, 'bool', 'base');

# file_ext_2_proc - long default string  

&config_init_value
(
	'file_ext_2_proc', 

	"aac|aiff|ape|asf|avi|bmp|flac|gif|jpeg|jpg|m4a|m4v|mkv|mov|mp2|mp3|mp4|mpc|mpg|mpeg|ogg|ogm|opus|png|rm|rmvb".
	"|svg|tif|tiff|webm|webp|wma|wmv", "aac|aiff|ape|asf|avi|bmp|flac|gif|jpeg|jpg|m4a|m4v|mkv|mov|mp2|mp3|mp4|mpc".
	"|mpg|mpeg|ogg|ogm|opus|png|rm|rmvb|svg|tif|tiff|webm|webp|wma|wmv", 

	'str', 
	'base'
);

# -----------------------------------------------------------------------------
# CONFIG DIALOG - DEBUG TAB

&config_init_value('debug', 		2, 2, 'int',	'base');
&config_init_value('log_stdout',	0, 0, 'bool',	'base');
&config_init_value('error_stdout',	0, 0, 'bool',	'base');
&config_init_value('error_notify',	0, 0, 'bool',	'base');
&config_init_value('zero_log',		1, 1, 'bool',	'base');


#######################################################################################################################
# File and array initialization moved to globals.pm
#######################################################################################################################

#######################################################################################################################
# functions
#######################################################################################################################

# reset config to defaults

sub reset_config
{
	for my $k(keys %hash)
	{
		if(! defined $hash{$k}{default})
		{
			print Dumper(\%hash);
			&main::quit("reset_config \$hash{$k}{default} is undef\n");
		}

		$hash{$k}{value} = $hash{$k}{default};
	}
}

sub save_hash
{
	&misc::plog(3, "saving config to file $globals::hash_tsv");
	
	# Try to create/clear the config file
	if (!&misc::null_file($globals::hash_tsv)) 
	{
		&misc::plog(0, "Failed to initialize config file for writing");
		return 0;
	}

	# Capture window geometry if in GUI mode and checkbox is checked
	$hash{window_g}{value} = $main::mw->geometry if !$globals::CLI && $hash{save_window_size}{value};

	# Conditional save categories based on checkbox states
	my @types = ('base');  # Always save base settings
	push @types, 'extended' if $save_extended;  # Save extended settings if checkbox checked
	push @types, 'geometry' if !$globals::CLI && $hash{save_window_size}{value};  # Save geometry if GUI mode and checkbox checked

	&misc::plog(3, "config saving types: ". join(", ", @types));

	for my $save_type (@types)
	{
		if (!&misc::file_append($globals::hash_tsv, "\n######## $save_type ########\n\n")) 
		{
			&misc::plog(0, "Failed to write config section header for $save_type");
			return 0;
		}

		for my $k(sort { lc $a cmp lc $b } keys %hash)
		{
			if(! defined $hash{$k})
			{
				print Dumper(\%hash);
				&main::quit("\$hash{$k} is undef\n");
			}

			if(! defined $hash{$k}{save})
			{
				print Dumper(\%hash);
				&main::quit("\$hash{$k}{save} is undef\n");
			}

			next if $hash{$k}{save} ne $save_type;
			if (!save_hash_helper($k)) 
			{
				&misc::plog(0, "Failed to save config key: $k");
				return 0;
			}
		}
	}
	&misc::plog(3, "config saved OK");
	return 1;
}

sub save_hash_helper
{
	my $k = shift;
	my $k_lower = lc($k);

	# there should be no mixed case keys
	# but if there are warn and save as lowercase
	&misc::plog(1, "non lowercase config key '$k' found in hash") if($k ne $k_lower && defined $hash{$k}) ;

	# unlikely to happen but just in case checks
	if(!defined $hash{$k}) {
		&misc::plog(0, "config::save_hash key '$k' not found in hash");
		return 0;
	}
	if(!defined $hash{$k}{value}) {
		&misc::plog(0, "config::save_hash \$hash{$k}{value} is undef");
		return 0;
	}
	
	return &misc::file_append($globals::hash_tsv, "$k_lower\t\t".$hash{$k}{value}."\n");
}

sub load_hash
{
	&misc::plog(3, "config::save_hash $globals::hash_tsv");
	my @tmp = &misc::readf($globals::hash_tsv);
	my %h = ();
	for my $line(@tmp)
	{
		$line =~ s/(\n|\r)+$//;

		next if $line !~ /.+\t.*/;
		next if($line !~ /(\S+)\t+(.*?)$/);	# warning this can sometimes match a tab. fixed below
		my ($k, $v) = ($1, $2);
		next if $v eq "\t";

		# Convert key to lowercase for backward compatibility with old config files
		my $k_lower = lc($k);
		
		# Migration table for renamed variables
		my %migration_map = (
			'audio_force' => 'id3_force',
			'rm_audio_tags' => 'id3_tags_rm', 
			'audio_set_artist' => 'id3_set_artist',
			'audio_set_album' => 'id3_set_album',
			'audio_set_genre' => 'id3_set_genre',
			'audio_set_year' => 'id3_set_year',
			'audio_set_comment' => 'id3_set_comment'
		);
		
		# Check for migration
		my $target_key = $k;
		if (exists $migration_map{$k_lower}) {
			$target_key = $migration_map{$k_lower};
			&misc::plog(1, "config: migrating old config key '$k' to '$target_key'");
		}
		
		# Check if target key exists (original, lowercase, or migrated)
		if (!defined $hash{$target_key} && !defined $hash{$k_lower} && !defined $hash{$k}) {
			&misc::plog(1, "config: skipping unknown config key '$k' (deprecated or removed)");
			next;
		}
		
		# Use the best available key
		if (defined $hash{$target_key}) {
			# Migration target exists
		} elsif (defined $hash{$k_lower}) {
			$target_key = $k_lower;
		} else {
			$target_key = $k;
		}
		$h{$target_key} = $v;
	}

	for my $k(keys %h)
	{
		$hash{$k}{value} = $h{$k};
	}
}

#--------------------------------------------------------------------------------------------------------------
# Save Config File
#--------------------------------------------------------------------------------------------------------------

sub halt
{
	$globals::LISTING	= 0;	# set LISTING
	$globals::PREVIEW	= 1;	# revert to preview mode
	$globals::RUN		= 0;	# turn RUN off
	$globals::STOP		= 1;	# set STOP
}

#--------------------------------------------------------------------------------------------------------------
# clear options
#--------------------------------------------------------------------------------------------------------------

sub clr_no_save
{
	# Clear all options that have save = 'no' by resetting them to their defaults
	for my $k (keys %hash)
	{
		if (defined $hash{$k}{save} && $hash{$k}{save} eq 'no')
		{
			if (!defined $hash{$k}{default})
			{
				print Dumper(\%hash);
				&main::quit("clr_no_save: \$hash{$k}{default} is undef\n");
			}
			$hash{$k}{value} = $hash{$k}{default};
		}
	}
}

sub clr_id3_options
{
	for my $k (keys %config::hash)
	{
		if ($k =~ /^id3_/)
		{
			if (!defined $config::hash{$k}{default})
			{
				print Dumper(\%config::hash);
				&main::quit("clr_id3_options: \$config::hash{$k}{default} is undef\n");
			}
			$config::hash{$k}{value} = $config::hash{$k}{default};
		}
	}

		&misc::plog(2, 'cleared id3 options');
}

sub set_value
{
	my ($key, $value) = @_;

	if(!defined $key)
	{
		&misc::plog(0, "config::set_value key is undef");
	}
	if(!defined $value)
	{
		&misc::plog(0, "config::set_value value is undef");
	}
	if(!defined $hash{$key})
	{
		&misc::plog(0, "config::set_value key '$key' not found in config hash");
	}

	if($hash{$key}{type} eq 'bool')
	{
		if ($value =~ /^(1|true|on|yes)$/i)
		{
			$hash{$key}{value} = 1;

			return;
		}
		elsif ($value =~ /^(0|false|off|no)$/i)
		{
			$hash{$key}{value} = 0;

			return;
		}
		&misc::plog(0, "config::set_value $key invalid bool value '$value'");
		&main::quit("config::set_value $key invalid bool value '$value'");

		return; # should never get here
	}

	# int
	if($hash{$key}{type} eq 'int')
	{
		if($value !~ /^-?\d+$/)
		{
			&misc::plog(0, "config::set_value $key invalid int value '$value'");
			&main::quit("config::set_value $key invalid int value '$value'");
		}
		$hash{$key}{value} = int($value);

		return;
	}

	# str - no checks
	if($hash{$key}{type} eq 'str')
	{
		# no checks
		$hash{$key}{value} = $value;

		return;
	}	

	# unknown type

	&misc::plog(0, "config::set_value $key unknown type '".$hash{$key}{type}."'");
	&main::quit("config::set_value $key unknown type '".$hash{$key}{type}."'");

	return; # should never get here
}

# deliberately no checks. used only by this library to reduce code duplication

# example: &config_init_value('exit_on_error', 0, 0, 'bool', 'base');

# ordering logic
# key 
# values (value and default) 
# descriptors (type and save)

sub config_init_value
{
	my $key = shift;
	$hash{$key}				= {};
	$hash{$key}{value}		= shift; 
	$hash{$key}{default}	= shift;
	$hash{$key}{type}		= shift;
	$hash{$key}{save}		= shift;
}

1;

