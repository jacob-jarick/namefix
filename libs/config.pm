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

our $dir				= cwd;
our $cwd				= cwd;
our $hlist_cwd			= cwd;

our $version 			= '4.1.8';
our $folderimage 		= '';
our $fileimage   		= '';

$hash{debug}			{save}	= 'base';
$hash{debug}			{value}	= 0;

$hash{log_stdout}		{save}	= 'base';
$hash{log_stdout}		{value}	= 0;

$hash{error_stdout}		{save}	= 'base';
$hash{error_stdout}		{value}	= 1;

$hash{error_notify}		{save}	= 'base';
$hash{error_notify}		{value}	= 1;

$hash{zero_log}			{save}	= 'base';
$hash{zero_log}			{value}	= 1;

our $g_font				= '';
our $home				= &misc::get_home;

# File locations
our $thanks				= "$Bin/data/txt/thanks.txt";
our $todo				= "$Bin/data/txt/todo.txt";
our $about				= "$Bin/data/txt/about.txt";
our $links				= "$Bin/data/txt/links.txt";
our $changelog			= "$Bin/data/txt/changelog.txt";
our $mempic				= "$Bin/data/mem.jpg";
our $fonts_file			= "$home/.namefix.pl/fonts.ini";
our $bookmark_file		= "$home/.namefix.pl/bookmarks.txt";
our $undo_cur_file		= "$home/.namefix.pl/undo.current.filenames.txt";
our $undo_pre_file		= "$home/.namefix.pl/undo.previous.filenames.txt";
our $undo_dir_file		= "$home/.namefix.pl/undo.dir.txt";

# system internal FLAGS
our $CLI				= 0;
our $FOUND_TMP	 		= 0;
our $LISTING			= 0;
our $PREVIEW			= 1;
our $RUN				= 0;
our $STOP				= 0;
our $MR_DONE			= 0;	# a manual rename has occured
our $UNDO				= 0;
our $SUGGEST_FSFIX		= 0;	# suggest using fsfix var

# undo VARS
our @undo_cur			= ();	# undo array - current filenames
our @undo_pre			= ();	# undo array - previous filenames
our $undo_dir			= '';	# directory to perform undo in

# hlist vars
our $hlist_newfile_row	= 0;
our $hlist_file_row		= 1;
our $change 			= 0;
our $delay				= 3;		# delay
our $update_delay		= $delay;	# initial value
our $hlist_file			= '';
our $hlist_file_new		= '';

# misc vars
our $tags_rm			= 0;	# counter for number of tags removed
our @find_arr			= ();
our $tmpfilelist 		= '';
our $last_recr_dir 		= '';

# writable_extensions - stolen from mp3::tag and tidied
our @id3v2_exts 		= ('aac', 'aiff', 'ape', 'flac', 'm4a', 'mp2', 'mp3', 'mp4', 'mpc', 'ogg', 'opus', 'wma');
our $id3_ext_regex 		= join('|', @id3v2_exts);

our @exif_exts = 
(
	'3fr', 'arw', 'bmp', 'cr2', 'cr3', 'crw', 'dcr', 'dng', 'erf', 'gif', 
	'heic', 'heif', 'jpeg', 'jpg', 'kdc', 'mef', 'mos', 'mrw', 'nef', 'nrw', 
	'orf', 'pef', 'png', 'raf', 'raw', 'rw2', 'sr2', 'srf', 'tif', 'tiff', 
	'x3f'
);

our $hash_tsv			= &misc::get_home."/.namefix.pl/config_hash.tsv";

#############################################################################################
# MAIN TAB

$hash{cleanup_general}		{save}	= 'extended';
$hash{cleanup_general}		{value}	= 0;

$hash{case}					{save}	= 'extended';
$hash{case}					{value}	= 0;

$hash{word_special_casing}	{save}	= 'extended';
$hash{word_special_casing}	{value}	= 0;

$hash{spaces}				{save}	= 'extended';
$hash{spaces}				{value}	= 0;

$hash{dot2space}			{save}	= 'extended';
$hash{dot2space}			{value}	= 0;

$hash{kill_cwords}			{save}	= 'extended';
$hash{kill_cwords}			{value}	= 0;

$hash{kill_sp_patterns}		{save}	= 'extended';
$hash{kill_sp_patterns}		{value}	= 0;

$hash{replace}				{save}	= 'extended';
$hash{replace}				{value}	= 0;

$hash{ins_end}				{save}	= 'extended';
$hash{ins_end}				{value}	= 0;
$hash{ins_start}			{save}	= 'extended';
$hash{ins_start}			{value}	= 0;

our $ins_front_str	= '';
our $ins_end_str	= '';
our $ins_str_old	= '';
our $ins_str		= '';

#############################################################################################
# MP3 TAB

$hash{id3_mode}				{save}	= 'extended';
$hash{id3_mode}				{value}	= 0;

$hash{id3_guess_tag}		{save}	= 'extended';
$hash{id3_guess_tag}		{value}	= 0;

$hash{audio_force}			{save}	= 'extended';
$hash{audio_force}			{value}	= 0;

$hash{rm_audio_tags}		{save}	= 'extended';
$hash{rm_audio_tags}		{value}	= 0;

$hash{audio_set_artist}		{save}	= 'extended';
$hash{audio_set_artist}		{value}	= 0;

$hash{audio_set_album}		{save}	= 'extended';
$hash{audio_set_album}		{value}	= 0;

$hash{audio_set_genre}		{save}	= 'extended';
$hash{audio_set_genre}		{value}	= 0;

$hash{audio_set_year}		{save}	= 'extended';
$hash{audio_set_year}		{value}	= 0;

$hash{audio_set_comment}	{save}	= 'extended';
$hash{audio_set_comment}	{value}	= 0;

# id3 tag txt
our $id3_alb_str	= '';
our $id3_art_str	= '';
our $id3_tra_str	= '';
our $id3_tit_str	= '';
our $id3_gen_str	= '';
our $id3_year_str	= '';
our $id3_com_str	= '';


#############################################################################################
# MISC TAB

$hash{uc_all}				{save}	= 'extended';
$hash{uc_all}				{value}	= 0;

$hash{lc_all}				{save}	= 'extended';
$hash{lc_all}				{value}	= 0;

$hash{intr_char}			{save}	= 'extended';
$hash{intr_char}			{value}	= 0;

$hash{sp_char}				{save}	= 'extended';
$hash{sp_char}				{value}	= 0;

$hash{rm_digits}			{save}		= 'extended'; #	RM ^Digits
$hash{rm_digits}			{value}		= 0;

$hash{digits}				{save}		= 'extended';
$hash{digits}				{value}		= 0;

$hash{unscene}				{save}	= 'extended';
$hash{unscene}				{value}	= 0;

$hash{scene}				{save}	= 'extended';
$hash{scene}				{value}	= 0;

$hash{pad_N_to_NN}			{save}	= 'extended';
$hash{pad_N_to_NN}			{value}	= 0;

$hash{pad_dash}				{save}	= 'extended';
$hash{pad_dash}				{value}	= 0;

$hash{pad_digits}			{save}	= 'extended';
$hash{pad_digits}			{value}	= 0;

$hash{pad_digits_w_zero}	{save}	= 'extended';
$hash{pad_digits_w_zero}	{value}	= 0;

$hash{split_dddd}			{save}	= 'extended';
$hash{split_dddd}			{value}	= 0;

#############################################################################################
# ENUMURATE TAB

$hash{enum}				{save}	= 'extended';
$hash{enum}				{value}	= 0;

$hash{enum_opt}			{save}	= 'extended';
$hash{enum_opt}			{value}	= 0;

$hash{enum_add}			{save}	= 'extended';
$hash{enum_add}			{value}	= 0;

our $enum_start_str		= '';
our $enum_end_str		= '';

$hash{enum_pad}			{save}	= 'extended';
$hash{enum_pad}			{value}	= 0;

$hash{enum_pad_zeros}	{save}	= 'extended';
$hash{enum_pad_zeros}	{value}	= 4;

#############################################################################################
# TRUNCATE TAB

$hash{truncate}			{save}	= 'extended';
$hash{truncate}			{value}	= 0;

$hash{truncate_to}		{save}	= 'extended';
$hash{truncate_to}		{value}	= 256;

$hash{truncate_style}	{save}	= 'extended';
$hash{truncate_style}	{value}	= 0;

$hash{trunc_char}		{save}	= 'extended';
$hash{trunc_char}		{value}	= '';

#############################################################################################
# EXIF TAB

$hash{exif_show}		{save}	= 'extended';
$hash{exif_show}		{value}	= 0;

$hash{exif_rm_all}		{save}	= 'extended';
$hash{exif_rm_all}		{value}	= 0;


#############################################################################################
# FILTER BAR

$hash{filter}				{save}	= 'extended';
$hash{filter}				{value}	= 0;

$hash{filter_ignore_case}	{save}	= 'extended';
$hash{filter_ignore_case}	{value}	= 0;

our $filter_string	= '';

#############################################################################################
# bottom menu bar

$hash{recursive}		{save}		= 'base';
$hash{recursive}		{value}		= 0;

$hash{ignore_file_type}	{save}		= 'extended';
$hash{ignore_file_type}	{value}		= 0;

$hash{proc_dirs}		{save}		= 'extended';
$hash{proc_dirs}		{value}		= 0;

#############################################################################################
# CLI ONLY OPTIONS

$hash{html_hack}		{save}	= 'base';
$hash{html_hack}		{value}	= 0;

$hash{browser}			{save}	= 'base';
$hash{browser}			{value}	= 'elinks';

$hash{editor}			{save}	= 'base';
$hash{editor}			{value}	= 'vim';

#############################################################################################
# CONFIG DIALOG - MAIN TAB

$hash{space_character}		{save}	= 'base';
$hash{space_character}		{value}	= ' ';

$hash{max_fn_length}		{save}	= 'base';
$hash{max_fn_length}		{value}	= 256;

$hash{save_window_size}		{save}	= 'base';
$hash{save_window_size}		{value}	= 0;

$hash{window_g}				{save}	= 'geometry';
$hash{window_g}				{value}	= '';

our $save_extended			= 0;	# save main window options

#############################################################################################
# CONFIG DIALOG - ADVANCED TAB

$hash{fat32fix}				{save}	= 'base';
$hash{fat32fix}				{value}	= 0;
$hash{fat32fix}				{value}	= 1 if lc $^O eq 'mswin32';

$hash{filter_regex}			{save}	= 'base';
$hash{filter_regex}			{value}	= 0;

$hash{file_ext_2_proc}		{save}	= 'base';
$hash{file_ext_2_proc}		{value}	= "aac|aiff|ape|asf|avi|bmp|flac|gif|jpeg|jpg|m4a|m4v|mkv|mov|mp2|mp3|mp4|mpc|mpg|mpeg|ogg|ogm|opus|png|rm|rmvb|svg|tif|tiff|webm|webp|wma|wmv";

$hash{overwrite}			{save}	= 'base';
$hash{overwrite}			{value}	= 0;

$hash{remove_regex}			{save}	= 'base';
$hash{remove_regex}			{value}	= 0;

#############################################################################################
# CONFIG DIALOG - DEBUG TAB

$hash{debug}			{save}	= 'base';
$hash{debug}			{value}	= 2;

$hash{log_stdout}		{save}	= 'base';
$hash{log_stdout}		{value}	= 0;

$hash{error_stdout}		{save}	= 'base';
$hash{error_stdout}		{value}	= 0;

$hash{error_notify}		{save}	= 'base';
$hash{error_notify}		{value}	= 0;

$hash{zero_log}			{save}	= 'base';
$hash{zero_log}			{value}	= 1;

#############################################################################################
# DONE - MENU CLI and DIALOG options - DONE
#############################################################################################

# ==============================================================================
# files and arrays


our $killwords_file 	= "$home/.namefix.pl/list_rm_words.txt";
our $killwords_defaults	= "$Bin/data/defaults/killwords.txt";
our @kill_words_arr		= ();
@kill_words_arr			= &misc::readf_clean($killwords_defaults)	if -f $killwords_defaults;
@kill_words_arr			= &misc::readf_clean($killwords_file)		if -f $killwords_file;

our $casing_file    	= "$home/.namefix.pl/list_special_word_casing.txt";
our $casing_defaults   	= "$Bin/data/defaults/special_casing.txt";
our @word_casing_arr	= ();
@word_casing_arr		= misc::readf_clean($casing_defaults)		if -f $casing_defaults;
@word_casing_arr		= misc::readf_clean($casing_file)			if -f $casing_file;

our $killpat_file   	= "$home/.namefix.pl/killpatterns.txt";
our $killpat_defaults  	= "$Bin/data/defaults/killpatterns.txt";
our @kill_patterns_arr	= ();
@kill_patterns_arr		= &misc::readf_clean($killpat_defaults)		if -f $killpat_defaults;
@kill_patterns_arr		= &misc::readf_clean($killpat_file)			if -f $killpat_file;

our $genres_file		= "$Bin/data/txt/genres.txt";
our @genres				= ();
@genres					= misc::readf_clean($genres_file)			if -f $genres_file;


sub save_hash
{
	my $dry_run = shift || 0;  # Optional dry run parameter
	
	&misc::plog(3, "config::save_hash $hash_tsv") unless $dry_run;
	&misc::null_file($hash_tsv) unless $dry_run;

	# Capture window geometry if in GUI mode and checkbox is checked
	$hash{window_g}{value} = $main::mw->geometry if !$CLI && $hash{save_window_size}{value} && !$dry_run;

	# Conditional save categories based on checkbox states
	my @types = ('base');  # Always save base settings
	push @types, 'extended' if $save_extended;  # Save extended settings if checkbox checked
	push @types, 'geometry' if !$CLI && $hash{save_window_size}{value};  # Save geometry if GUI mode and checkbox checked

	return @types if $dry_run;  # Return categories for testing

	for my $t (@types)
	{
		&misc::file_append($hash_tsv, "\n######## $t ########\n\n");

		for my $k(sort { lc $a cmp lc $b } keys %hash)
		{
			if(! defined $hash{$k})
			{
				print Dumper(\%hash);
				&main::quit("save_hash \$hash{$k} is undef\n");
			}

			if(! defined $hash{$k}{save})
			{
				print Dumper(\%hash);
				&main::quit("save_hash \$hash{$k}{save} is undef\n");
			}

			next if $hash{$k}{save} ne $t;
			save_hash_helper($k);
		}
	}
}

sub save_hash_helper
{
	my $k = shift;
	&main::quit("config::save_hash key '$k' not found in hash". Dumper($hash{$k})) if(!defined $hash{$k});
	&main::quit("config::save_hash \$hash{$k}{value} is undef". Dumper($hash{$k})) if(!defined $hash{$k}{value});
	# Always save keys in lowercase
	my $k_lower = lc($k);
	&misc::file_append($hash_tsv, "$k_lower\t\t".$hash{$k}{value}."\n");
}

sub load_hash
{
	&misc::plog(3, "config::save_hash $hash_tsv");
	my @tmp = &misc::readf($hash_tsv);
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
		
		# Check both original case and lowercase versions for compatibility
		if (!defined $hash{$k} && !defined $hash{$k_lower}) {
			&main::quit("load_hash: unknown value '$k' in config hash.tsv");
		}

		# Use lowercase key for storage
		my $target_key = defined $hash{$k_lower} ? $k_lower : $k;
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

# MEMO: to self, config file is for stuff under prefs dialog only and defaults is for mainwindow vars

sub halt
{
	$LISTING	= 0;	# set LISTING
	$PREVIEW	= 1;	# revert to preview mode
	$RUN		= 0;	# turn RUN off
	$STOP		= 1;	# set STOP
}

# return 1 if we are doing something
sub busy
{
	return 1 if $LISTING;
# 	return 1 if $PREVIEW;
	return 1 if $RUN;
	return 0 if $STOP;
}

# return 1 if we are doing something
sub mode
{
	return 'stop'		if $STOP;
	return 'list' 		if $LISTING;
 	return 'preview'	if $PREVIEW;
	return 'rename'		if $RUN;
}

1;
