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

our $version 			= '4.1.31';
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

our $PREVIEW			= 1;	# preview mode - do not actually rename files

our $LISTING			= 0;	# directory listing in progress
our $RUN				= 0;	# rename or preview in progress
our $IDLE				= 1;	# default state - not doing anything

our $STOP				= 0;	# emergency stop flag

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
our $id3_ext_regex 		= join('|', sort @id3v2_exts);

our @exif_exts = 
(
	'3fr',  'arw',  'bmp',  'cr2',  'cr3',  'crw',  'dcr',  'dng',  'erf',  'gif', 
	'heic', 'heif', 'jpeg', 'jpg',  'kdc',  'mef',  'mos',  'mrw',  'nef',  'nrw', 
	'orf',  'pef',  'png',  'raf',  'raw',  'rw2',  'sr2',  'srf',  'tif',  'tiff', 
	'x3f'
);

our @media_exts = 
(
	'aac',  'aiff', 'ape',  'asf', 'avi',  'bmp',  'flac', 
	'gif',  'jpeg', 'jpg',  'm4a', 'm4v',  'mkv',  'mov', 
	'mp2',  'mp3',  'mp4',  'mpc', 'mpg',  'mpeg', 'ogg', 
	'ogm',  'opus', 'png',  'rm',  'rmvb', 'svg',  'tif', 
	'tiff', 'webm', 'webp', 'wma', 'wmv'
);

our $media_ext_regex = join('|', sort @media_exts);

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

1;