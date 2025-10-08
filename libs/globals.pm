package globals;

use strict;
use warnings;
use FindBin qw($Bin);
use Cwd;

require misc;

#=============================================================================
# GLOBALS.PM - Global Variables and File/Array Initialization
#=============================================================================
# This module contains all global variables that were previously in config.pm
# Separated to maintain clean architecture: config = settings, globals = state
#=============================================================================

#=============================================================================
# GLOBAL VARIABLES
#=============================================================================

our $dir				= cwd;
our $home				= &misc::get_home;

our $version 			= '4.1.16';
our $folderimage 		= '';
our $fileimage   		= '';

# Text files
our $thanks				= "$Bin/data/txt/thanks.txt";
our $todo				= "$Bin/data/txt/todo.txt";
our $about				= "$Bin/data/txt/about.txt";
our $links				= "$Bin/data/txt/links.txt";
our $changelog			= "$Bin/data/txt/changelog.txt";

# about image files
our $mem_jpg			= "$Bin/data/mem.jpg";
our $mem_ppm			= "$Bin/data/mem.ppm";

# config files
our $fonts_file			= "$home/.namefix.pl/fonts.ini";

our $bookmark_file		= "$home/.namefix.pl/bookmarks.txt";

our $undo_cur_file		= "$home/.namefix.pl/undo.current.filenames.txt";
our $undo_pre_file		= "$home/.namefix.pl/undo.previous.filenames.txt";
our $undo_dir_file		= "$home/.namefix.pl/undo.dir.txt";

our $hash_tsv			= "$home/.namefix.pl/config_hash.tsv";


# system internal FLAGS
our $CLI				= 0;
our $FOUND_TMP	 		= 0;
our $LISTING			= 0;
our $PREVIEW			= 1;
our $RUN				= 0;
our $STOP				= 0;
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
our $exif_rm			= 0;	# counter for number of exif data removed
our @find_arr			= ();
our $tmpfilelist 		= '';
our $last_recr_dir 		= '';

our @id3v2_exts 		= ('aac', 'aiff', 'ape', 'flac', 'm4a', 'mp2', 'mp3', 'mp4', 'mpc', 'ogg', 'opus', 'wma');
our $id3_ext_regex 		= join('|', @id3v2_exts);

our @exif_exts = 
(
	'3fr', 'arw', 'bmp', 'cr2', 'cr3', 'crw', 'dcr', 'dng', 'erf', 'gif', 
	'heic', 'heif', 'jpeg', 'jpg', 'kdc', 'mef', 'mos', 'mrw', 'nef', 'nrw', 
	'orf', 'pef', 'png', 'raf', 'raw', 'rw2', 'sr2', 'srf', 'tif', 'tiff', 
	'x3f'
);

#=============================================================================
# FILE AND ARRAY INITIALIZATION
#=============================================================================

# Kill words
our $killwords_file 	= "$home/.namefix.pl/list_rm_words.txt";
our $killwords_defaults	= "$Bin/data/defaults/killwords.txt";
our @kill_words_arr		= ();

# Word casing
our $casing_file    	= "$home/.namefix.pl/list_special_word_casing.txt";
our $casing_defaults   	= "$Bin/data/defaults/special_casing.txt";
our @word_casing_arr	= ();

# Kill patterns
our $killpat_file		= "$home/.namefix.pl/killpatterns.txt";
our $killpat_defaults	= "$Bin/data/defaults/killpatterns.txt";
our @kill_patterns_arr	= ();

# Genres
our $genres_file		= "$Bin/data/txt/genres.txt";
our @genres				= ();

&init_globals();

#=============================================================================
# INITIALIZATION FUNCTION
#=============================================================================

sub init_globals 
{
	@kill_words_arr		= ();
	@kill_words_arr		= &misc::readf_clean($killwords_defaults)	if -f $killwords_defaults;
	@kill_words_arr		= &misc::readf_clean($killwords_file)		if -f $killwords_file;
	
	@word_casing_arr	= ();
	@word_casing_arr	= misc::readf_clean($casing_defaults)		if -f $casing_defaults;
	@word_casing_arr	= misc::readf_clean($casing_file)			if -f $casing_file;
	
	@kill_patterns_arr	= ();
	@kill_patterns_arr	= &misc::readf_clean($killpat_defaults)		if -f $killpat_defaults;
	@kill_patterns_arr	= &misc::readf_clean($killpat_file)			if -f $killpat_file;
	
	@genres				= ();
	@genres				= misc::readf_clean($genres_file)			if -f $genres_file;
}

# return 1 if we are doing something
sub mode_check
{
	my $check = shift;

	if(! defined $check)
	{
		&misc::plog(0, "sub mode_check: error, \$check is undef");
		return 0;
	}
	if($check eq '')
	{
		&misc::plog(0, "sub mode_check: error, \$check is blank");
		return 0;
	}

	$check = lc $check;

	return 1 if $globals::STOP		&& $check eq 'stop';
	return 1 if $globals::LISTING	&& $check eq 'list';
	return 1 if $globals::PREVIEW	&& $check eq 'preview';
	return 1 if $globals::RUN		&& $check eq 'rename';

	# Check if it's a valid mode but the flag is just false
	if ($check eq 'stop' || $check eq 'list' || $check eq 'preview' || $check eq 'rename') {
		return 0;  # Valid mode, but flag is false
	}

	&misc::plog(0, "sub mode_check: error, unknown check '$check'");

	return 0;
}

# return 1 if we are doing something
sub busy
{
	return 1 if $globals::LISTING;
# 	return 1 if $globals::PREVIEW;
	return 1 if $globals::RUN;
	return 0 if $globals::STOP;
}

1;