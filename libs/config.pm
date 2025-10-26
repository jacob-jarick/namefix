package config;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;
use Cwd;
use Data::Dumper::Concise;
use FindBin qw($Bin);

require misc;
require globals;

# -----------------------------------------------------------------------------

our %hash = ();

&config_init_value('exit_on_error',		0, 0, 'bool', 'base'); # CLI: --exit-on-error / GUI: 'Exit on error' (libs/gui/config_dialog.pm)
&config_init_value('debug',				0, 0, 'int', 'base'); # CLI: --debug=N / GUI: 'Debug Level:' (libs/gui/config_dialog.pm)
&config_init_value('error_notify',		1, 1, 'bool', 'base'); # CLI: N/A / GUI: 'Show errors in dialog boxes' (libs/gui/config_dialog.pm)

# -----------------------------------------------------------------------------
# MAIN TAB

&config_init_value('cleanup_general',		0, 0, 'bool', 'extended'); # CLI: --clean / GUI: 'General Cleanup'
&config_init_value('case',					0, 0, 'bool', 'extended'); # CLI: --case / GUI: 'Normal Casing'
&config_init_value('word_special_casing',	0, 0, 'bool', 'extended'); # CLI: --case-sp / GUI: 'Specific Casing'
&config_init_value('spaces',				0, 0, 'bool', 'extended'); # CLI: --spaces / GUI: 'Spaces'
&config_init_value('dot2space',				0, 0, 'bool', 'extended'); # CLI: --dots / GUI: '. to Space'
&config_init_value('kill_cwords',			0, 0, 'bool', 'extended'); # CLI: --rm-words / GUI: 'RM Word List'
&config_init_value('kill_sp_patterns',		0, 0, 'bool', 'extended'); # CLI: --rm-patterns / GUI: 'RM Pattern List'
&config_init_value('replace',				0, 0, 'bool', 'no'); # CLI: --replace / GUI: 'Replace With'
&config_init_value('ins_end',				0, 0, 'bool', 'no'); # CLI: --append-end / GUI: 'End Append'
&config_init_value('ins_start',				0, 0, 'bool', 'no'); # CLI: --ins-start / GUI: 'Start Prepend'

# String variables for remove/replace/append operations (never saved)

&config_init_value('ins_str_old',	'', '', 'str', 'no'); # CLI: --replace (old) / GUI: 'Replace With (old)'
&config_init_value('ins_str',		'', '', 'str', 'no'); # CLI: --replace (new) / GUI: 'Replace With (new)'
&config_init_value('ins_front_str',	'', '', 'str', 'no'); # CLI: --ins-front / GUI: 'Front Append'
&config_init_value('ins_end_str',	'', '', 'str', 'no'); # CLI: --ins-end / GUI: 'End Append'

# ID3 tag string variables (never saved)

# its metal just to select a genre so combo box isnt blank
&config_init_value('id3_gen_str',	'Metal',	'Metal',	'str', 'no'); # CLI: --id3-gen / GUI: 'Genre'
# the rest of these are blank
&config_init_value('id3_art_str',	'',			'',			'str', 'no'); # CLI: --id3-art / GUI: 'Set Artist as:'
&config_init_value('id3_tit_str',	'',			'',			'str', 'no'); # CLI: --id3-alb / GUI: N/A
&config_init_value('id3_com_str',	'',			'',			'str', 'no'); # CLI: --id3-com / GUI: 'Set Comment as:'
&config_init_value('id3_alb_str',	'',			'',			'str', 'no'); # CLI: --id3-alb / GUI: 'Set Album as:'
&config_init_value('id3_tra_str',	'',			'',			'str', 'no'); # CLI: --id3-tra / GUI: N/A
&config_init_value('id3_year_str',	'',			'',			'str', 'no'); # CLI: --id3-year / GUI: N/A

&config_init_value('id3_fn_from_tag',	0, 0, 'bool',	'no'); # CLI: --id3-fn-from-tag / GUI: N/A
&config_init_value('id3_fn_style', 		0, 0, 'int',	'no'); # CLI: --id3-fn-style / GUI: N/A

# -----------------------------------------------------------------------------
# MP3 TAB

&config_init_value('id3_mode',			0, 0, 'bool', 'extended'); # CLI: automatically set by other id3 arguments / GUI: 'Process Tags'
&config_init_value('id3_guess_tag',		0, 0, 'bool', 'extended'); # CLI: --id3-guess / GUI: 'Guess Tags'
&config_init_value('id3_force',			0, 0, 'bool', 'extended'); # CLI: --id3-force / GUI: 'Overwrite'
&config_init_value('id3_tags_rm',		0, 0, 'bool', 'no'); # CLI: --id3-rm / GUI: 'RM id3 tags'
&config_init_value('id3_set_artist',	0, 0, 'bool', 'no'); # CLI: --id3-art / GUI: 'Set Artist as:'
&config_init_value('id3_set_album',		0, 0, 'bool', 'no'); # CLI: --id3-alb / GUI: 'Set Album as:'
&config_init_value('id3_set_genre',		0, 0, 'bool', 'no'); # CLI: --id3-gen / GUI: 'Set Genre as:'
&config_init_value('id3_set_year',		0, 0, 'bool', 'no'); # CLI: --id3-year / GUI: 'Set Year as:'
&config_init_value('id3_set_comment',	0, 0, 'bool', 'no'); # CLI: --id3-com / GUI: 'Set Comment as:'

# -----------------------------------------------------------------------------
# MISC TAB

&config_init_value('uc_all',			0, 0, 'bool', 'extended'); # CLI: --uc / GUI: 'Uppercase All'
&config_init_value('lc_all',			0, 0, 'bool', 'extended'); # CLI: --lc / GUI: 'Lowercase All'
&config_init_value('intr_char',			0, 0, 'bool', 'extended'); # CLI: --int / GUI: 'International'
&config_init_value('c7bit',				0, 0, 'bool', 'extended'); # CLI: --7bit / GUI: '7bit ASCII'
&config_init_value('sp_char',			0, 0, 'bool', 'extended'); # CLI: --sp-char / GUI: 'RM Chars'
&config_init_value('rm_digits',			0, 0, 'bool', 'extended'); # CLI: --rm-starting-digits / GUI: 'RM ^Digits'
&config_init_value('digits',			0, 0, 'bool', 'extended'); # CLI: --rm-all-digits / GUI: 'RM all Digits'
&config_init_value('unscene',			0, 0, 'bool', 'extended'); # CLI: --unscene / GUI: 'Un=Scenify'
&config_init_value('scene',				0, 0, 'bool', 'extended'); # CLI: --scene / GUI: 'Scenify'
&config_init_value('pad_N_to_NN',		0, 0, 'bool', 'extended'); # CLI: --pad-ntonn / GUI: 'Pad N to NN' 
&config_init_value('pad_dash',			0, 0, 'bool', 'extended'); # CLI: --pad-hyphen / GUI: 'Pad - w space'
&config_init_value('pad_digits',		0, 0, 'bool', 'extended'); # CLI: --pad-num / GUI: 'Pad NN w -'
&config_init_value('pad_digits_w_zero', 0, 0, 'bool', 'extended'); # CLI: --pad-num-w0/ GUI: 'Pad NxNN w 0'
&config_init_value('split_dddd',		0, 0, 'bool', 'extended'); # CLI: --pad-nnnn-wx / GUI: 'Pad NNNN with x'

# -----------------------------------------------------------------------------
# ENUMURATE TAB

&config_init_value('enum',				0,	0,	'bool',	'extended'); # CLI: --enum / GUI: 'Enumerate'
&config_init_value('enum_opt',			0,	0,	'int',	'extended'); # CLI: --enum-style / GUI: "\nStyles:\n" (radio buttons)
&config_init_value('enum_add',			0,	0,	'bool',	'extended'); # CLI: --enum-add-strings / GUI: 'Add Strings'
&config_init_value('enum_pad',			0,	0,	'bool',	'extended'); # CLI: --enum-zero-pad / GUI: 'Pad with zeros'
&config_init_value('enum_pad_zeros',	4,	4,	'int',	'extended'); # CLI: --enum-zero-pad (value) / GUI: N/A (see spinbox $spin_pad_enum)
&config_init_value('enum_start_str',	'',	'',	'str',	'no'); # CLI: --enum-string-front / GUI: 'Start String:'
&config_init_value('enum_end_str',		'',	'',	'str',	'no'); # CLI: --enum-string-end / GUI: 'End String:'

# -----------------------------------------------------------------------------
# TRUNCATE TAB

&config_init_value('truncate',			0,		0,		'bool',	'extended'); # CLI: --trunc / GUI: 'Truncate'
&config_init_value('truncate_to',		256,	256,	'int',	'extended'); # CLI: --trunc-to / GUI: "\nFilename Length: "
&config_init_value('truncate_style',	0,		0,		'int',	'extended'); # CLI: --trunc-pat / GUI: "\nStyle:\n" (radio buttons)
&config_init_value('trunc_char',		'',		'',		'str',	'extended'); # CLI: --trunc-ins / GUI: "Insert Character\/s: "

# -----------------------------------------------------------------------------
# EXIF TAB

&config_init_value('exif_show',		0, 0, 'bool', 'extended'); # CLI: --exif-show / GUI: N/A
&config_init_value('exif_rm_all',	0, 0, 'bool', 'extended'); # CLI: --exif-rm / GUI: 'RM EXIF Tags'

# -----------------------------------------------------------------------------
# FILTER BAR

&config_init_value('filter',				0,		0,	'bool',	'extended'); # CLI: auto set if --filt=STRING is used / GUI 'Filter'
&config_init_value('filter_ignore_case',	0,		0,	'bool',	'extended'); # -CLI: --filt-ignore-case / GUI 'Case In-Sensitive'
&config_init_value('filter_string',			'',		'',	'str',	'no'); # CLI: --filt=STRING / GUI 'Filter String:'

# -----------------------------------------------------------------------------
# bottom menu bar

&config_init_value('recursive',			0,	0,	'bool',	'base'); # CLI: --rec / GUI: 'Recursive'
&config_init_value('ignore_file_type',	0,	0,	'bool',	'extended'); # CLI: --all-files / GUI: 'Ignore File Type'
&config_init_value('proc_dirs',			0,	0,	'bool',	'extended'); # CLI: --proc-dirs / GUI: 'Process ALL Files'

# -----------------------------------------------------------------------------
# CLI ONLY OPTIONS

&config_init_value('html_hack',			0,			0,			'bool',	'base'); # CLI: --html / GUI: N/A
&config_init_value('browser',			'elinks',	'elinks',	'str',	'base'); # CLI: --browser / GUI: N/A
&config_init_value('editor',			'vim', 		'vim',		'str',	'base'); # CLI: --editor / GUI: N/A

# This two options are not in the GUI but needed for CLI
# in the GUI the sub is triggered by a button

&config_init_value('undo',			0, 0, 'bool', 'no'); # CLI: --undo / GUI: N/A (see libs/gui/undo.pm)

# -----------------------------------------------------------------------------
# CONFIG DIALOG - MAIN TAB

&config_init_value('space_character',	' ',	' ',	'str',	'base'); # CLI: --space-char=C / GUI: 'Space Delimiter: (libs/gui/config_dialog.pm)
&config_init_value('max_fn_length',		256,	256,	'int',	'base'); # CLI: --max-fn-length / GUI: 'Max Filename Length: (libs/gui/config_dialog.pm)
&config_init_value('save_window_size',	0,		0,		'bool',	'base'); # CLI: N/A / GUI: 'Save main window size and position' (libs/gui/config_dialog.pm)
&config_init_value('window_g',			'',		'',		'str',	'geometry'); # CLI: N/A / GUI: auto set on save when save_window_size is checked

our $save_extended = 0;	# save main window options

# -----------------------------------------------------------------------------
# CONFIG DIALOG - ADVANCED TAB

# fat32fix - conditional default based on OS

# CLI: --fat32 / GUI: 'FS Fix (Case insensitive file system workaround)' (libs/gui/config_dialog.pm)
if(lc $^O eq 'mswin32')	# auto enable on windows
{
	&config_init_value('fat32fix', 1, 1, 'bool', 'base');
}
else
{
	&config_init_value('fat32fix', 0, 0, 'bool', 'base');
}

&config_init_value('filter_regex',	0, 0, 'bool', 'base'); # CLI: --filt-regexp / GUI: 'regex'
&config_init_value('overwrite',		0, 0, 'bool', 'base'); # CLI: --overwrite / GUI: N/A ( TODO ?? )
&config_init_value('remove_regex',	0, 0, 'bool', 'base'); # CLI: --rm-regex / GUI: 'Enable Regexp pattern matching for Remove option' (libs/gui/config_dialog.pm)

# file_ext_2_proc - long default string  

# CLI: --media-types=STRING / GUI: 'Media File Extensions: ' (libs/gui/config_dialog.pm)	
&config_init_value('file_ext_2_proc', $globals::media_ext_regex, $globals::media_ext_regex, 'str', 'base'); 

# -----------------------------------------------------------------------------
# CONFIG DIALOG - DEBUG TAB

&config_init_value('debug', 		2, 2, 'int',	'base'); # CLI: --debug=N / GUI: 'Debug Level:' (libs/gui/config_dialog.pm)
&config_init_value('error_notify',	0, 0, 'bool',	'base'); # CLI: N/A / GUI: 'Show errors in dialog boxes' (libs/gui/config_dialog.pm)
&config_init_value('zero_log',		1, 1, 'bool',	'base'); # CLI: --zero-log / GUI: 'Zero logfile on start'

# log_stdout
&config_init_value('log_stdout',	0, 0, 'bool',	'base'); # CLI: --log-stdout / GUI: 'Print log to STDOUT'

# ---------------------------------------------------------------------------------------------------------------
# reset_config
# ---------------------------------------------------------------------------------------------------------------

# reset config to defaults

sub reset_config
{
	for my $k(keys %hash)
	{
		if(! defined $hash{$k}{default})
		{
			print Dumper(\%hash);
			&misc::quit("reset_config \$hash{$k}{default} is undef\n");
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
				&misc::quit("\$hash{$k} is undef\n");
			}

			if(! defined $hash{$k}{save})
			{
				print Dumper(\%hash);
				&misc::quit("\$hash{$k}{save} is undef\n");
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

# ---------------------------------------------------------------------------------------------------------------
# load_hash
# ---------------------------------------------------------------------------------------------------------------

# load config from file

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

		# TODO: always use lowercase keys
		# Convert key to lowercase for backward compatibility with old config files
		my $k_lower = lc($k);
		
		# TODO: remove migration code. best to break old configs rather than keep legacy names forever
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
		if (defined $hash{$target_key}) 
		{
			# Migration target exists
		} 
		elsif (defined $hash{$k_lower}) 
		{
			$target_key = $k_lower;
		} 
		else 
		{
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
# clear options
#--------------------------------------------------------------------------------------------------------------

# Clear all options that have save = 'no' by resetting them to their defaults

sub clr_no_save
{
	for my $k (keys %hash)
	{
		if (defined $hash{$k}{save} && $hash{$k}{save} eq 'no')
		{
			if (!defined $hash{$k}{default})
			{
				print Dumper(\%hash);
				&misc::quit("clr_no_save: \$hash{$k}{default} is undef\n");
			}
			$hash{$k}{value} = $hash{$k}{default};
		}
	}
}

# --------------------------------------------------------------------------------------------------------------
# clear id3 options
# --------------------------------------------------------------------------------------------------------------

# used in GUI to clear all id3 related options in the MP3 tab

sub clr_id3_options
{
	for my $k (keys %config::hash)
	{
		if ($k =~ /^id3_/)
		{
			if (!defined $config::hash{$k}{default})
			{
				&misc::quit("clr_id3_options: '$k' has no default value in config\n");
			}
			$config::hash{$k}{value} = $config::hash{$k}{default};
		}
	}

	&misc::plog(2, 'cleared id3 options');
}

# --------------------------------------------------------------------------------------------------------------
# set_value
# --------------------------------------------------------------------------------------------------------------

# set a config value with checks

sub set_value
{
	my $key		= shift;
	my $value	= shift;

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
		&misc::plog(0, "config::set_value $key invalid bool value '$value'", 1);

		return; # should never get here
	}

	# int
	if($hash{$key}{type} eq 'int')
	{
		if($value !~ /^-?\d+$/)
		{
			&misc::plog(0, "config::set_value $key invalid int value '$value'", 1);
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

	&misc::plog(0, "config::set_value $key unknown type '".$hash{$key}{type}."'", 1);

	return; # should never get here
}

# --------------------------------------------------------------------------------------------------------------
# config_init_value
# --------------------------------------------------------------------------------------------------------------

# sets up $hash entries which represent config options

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

