package config;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;
use Cwd;
use Data::Dumper::Concise;
use FindBin qw($Bin);

our $version 		= "4.1.2";
our $home		= &misc::get_home;

our $load_defaults	= 0;
our $dir		= cwd;
our $cwd		= cwd;
our $hlist_cwd		= cwd;

# system internal vars
our $LISTING		= 0;
our $PREVIEW		= 0;
our $RUN		= 0;
our $STOP		= 0;

our $BR_DONE		= 0;	# a block rename has occured
our $MR_DONE		= 0;	# a manual rename has occured

our $LOG_STDOUT		= 0;
our $UNDO		= 0;

our $WORD_SPECIAL_CASING= 0;
our $SUGGEST_FSFIX 	= 0;	# suggest using fsfix var

# insert flags

# id3 tag txt
our $id3_alb_str	= '';
our $id3_art_str	= '';
our $id3_tra_str	= '';
our $id3_tit_str	= '';
our $id3_gen_str	= '';
our $id3_year_str	= '';
our $id3_com_str	= '';

# txt
our $ins_front_str	= '';
our $ins_end_str	= '';
our $ins_str_old	= '';
our $ins_str		= '';
our $filter_string	= '';

# truncate options

# undo options
our @undo_cur	= ();	# undo array - current filenames
our @undo_pre	= ();	# undo array - previous filenames
our $undo_dir	= '';	# directory to preform undo in

our $tags_rm		= 0;	# counter for number of tags removed
our @find_arr		= ();

our $hlist_newfile_row	= 0;
our $hlist_file_row	= 1;
our $change 		= 0;
our $id3_writeme	= 0;	# used for missing id3v1/id3v2 that can be filled in from each other
our $tmpfilefound 	= 0;
our $delay		= 3;		# delay
our $update_delay	= $delay;	# initial value

our $hlist_file		= '';
our $hlist_file_new	= '';
our $tmpfilelist 	= '';
our $last_recr_dir 	= '';

# writable_extensions - stolen from mp3::tag and tidied
our @id3v2_exts = ('mp3', 'mp2', 'ogg', 'mpg', 'mpeg', 'mp4', 'aiff', 'flac', 'ape', 'ram', 'mpc');
our $id3_ext_regex = join('|', @id3v2_exts);

# File locations
our $thanks		= "$Bin/txt/thanks.txt";
our $todo		= "$Bin/txt/todo.txt";
our $about		= "$Bin/txt/about.txt";
our $links		= "$Bin/txt/links.txt";
our $changelog		= "$Bin/txt/changelog.txt";;

our $fonts_file		= "$home/.namefix.pl/fonts.ini";
our $bookmark_file	= "$home/.namefix.pl/bookmarks.txt";
our $undo_cur_file	= "$home/.namefix.pl/undo.current.filenames.txt";
our $undo_pre_file	= "$home/.namefix.pl/undo.previous.filenames.txt";
our $undo_dir_file	= "$home/.namefix.pl/undo.dir.txt";

our %hash	= ();
our $hash_tsv	= &misc::get_home."/.namefix.pl/config_hash.tsv";

#############################################################################################
# MAIN TAB

$hash{CLEANUP_GENERAL}		{save}	= 'mw';
$hash{CLEANUP_GENERAL}		{value}	= 0;

$hash{case}			{save}	= 'mw';
$hash{case}			{value}	= 0;

$hash{WORD_SPECIAL_CASING}	{save}	= 'mw';
$hash{WORD_SPECIAL_CASING}	{value}	= 0;

$hash{spaces}			{save}	= 'mw';
$hash{spaces}			{value}	= 0;

$hash{dot2space}		{save}	= 'mw';
$hash{dot2space}		{value}	= 0;

$hash{kill_cwords}		{save}	= 'mw';
$hash{kill_cwords}		{value}	= 0;

$hash{kill_sp_patterns}		{save}	= 'mw';
$hash{kill_sp_patterns}		{value}	= 0;

$hash{replace}{save}		= 'mw';
$hash{replace}{value}		= 0;

$hash{INS_END}{save}		= 'mw';
$hash{INS_END}{value}		= 0;
$hash{INS_START}{save}		= 'mw';
$hash{INS_START}{value}		= 0;

#############################################################################################
# MP3 TAB

$hash{id3_mode}			{save}	= 'mw';
$hash{id3_mode}			{value}	= 0;

$hash{id3_guess_tag}		{save}	= 'mw';
$hash{id3_guess_tag}		{value}	= 0;



$hash{RM_AUDIO_TAGS}		{save}	= 'mw';
$hash{RM_AUDIO_TAGS}		{value}	= 0;
$hash{AUDIO_FORCE}		{save}	= 'mw';
$hash{AUDIO_FORCE}		{value}	= 0;
$hash{AUDIO_SET_ALBUM}		{save}	= 'mw';
$hash{AUDIO_SET_ALBUM}		{value}	= 0;
$hash{AUDIO_SET_COMMENT}	{save}	= 'mw';
$hash{AUDIO_SET_COMMENT}	{value}	= 0;
$hash{AUDIO_SET_ARTIST}		{save}	= 'mw';
$hash{AUDIO_SET_ARTIST}		{value}	= 0;
$hash{AUDIO_SET_GENRE}		{save}	= 'mw';
$hash{AUDIO_SET_GENRE}		{value}	= 0;
$hash{AUDIO_SET_YEAR}		{save}	= 'mw';
$hash{AUDIO_SET_YEAR}		{value}	= 0;

#############################################################################################
# MISC TAB

$hash{uc_all}{save}	= 'mw';
$hash{uc_all}{value}	= 0;

$hash{lc_all}{save}	= 'mw';
$hash{lc_all}{value}	= 0;

$hash{RM_DIGITS}{save}		= 'mw';
$hash{RM_DIGITS}{value}		= 0;

$hash{scene}			{save}	= 'mw';
$hash{scene}			{value}	= 0;

$hash{unscene}			{save}	= 'mw';
$hash{unscene}			{value}	= 0;

$hash{digits}{save}     	= 'mw';
$hash{digits}{value}     	= 0;

$hash{pad_dash}			{save}	= 'mw';
$hash{pad_dash}			{value}	= 0;

$hash{pad_digits}		{save}	= 'mw';
$hash{pad_digits}		{value}	= 0;

$hash{pad_digits_w_zero}	{save}	= 'mw';
$hash{pad_digits_w_zero}	{value}	= 0;

$hash{sp_char}			{save}	= 'mw';
$hash{sp_char}			{value}	= 0;

$hash{intr_char}		{save}	= 'mw';
$hash{intr_char}		{value}	= 0;

$hash{lc_all}			{save}	= 'mw';
$hash{lc_all}			{value}	= 0;

$hash{uc_all}			{save}	= 'mw';
$hash{uc_all}			{value}	= 0;

$hash{SPLIT_DDDD}		{save}	= 'mw';
$hash{SPLIT_DDDD}		{value}	= 0;

#############################################################################################
# ENUMURATE TAB

$hash{enum}		{save}	= 'mw';
$hash{enum}		{value}	= 0;
$hash{enum_opt}			{save}	= 'mw';
$hash{enum_opt}			{value}	= 0;

$hash{enum_pad}			{save}	= 'mw';
$hash{enum_pad}			{value}	= 0;

$hash{enum_pad_zeros}		{save}	= 'mw';
$hash{enum_pad_zeros}		{value}	= 4;

#############################################################################################
# TRUNCATE TAB

$hash{max_fn_length}		{save}	= 'norm';
$hash{max_fn_length}		{value}	= 256;
$hash{truncate}			{save}	= 'mw';
$hash{truncate}			{value}	= 0;

$hash{truncate_style}		{save}	= 'mw';
$hash{truncate_style}		{value}	= 0;

$hash{trunc_char}		{save}	= 'mw';
$hash{trunc_char}		{value}	= 0;

$hash{truncate_to}		{save}	= 'mw';
$hash{truncate_to}		{value}	= 256;

#############################################################################################
# FILTER BAR

$hash{FILTER}			{save}	= 'mw';
$hash{FILTER}			{value}	= 0;

$hash{FILTER_REGEX}		{save}	= 'norm';
$hash{FILTER_REGEX}		{value}	= 0;

#############################################################################################
# bottom menu bar

$hash{OVERWRITE}{save}		= 'norm';
$hash{OVERWRITE}{value}		= 0;
$hash{RECURSIVE}{save}		= 'norm';
$hash{RECURSIVE}{value}		= 0;

$hash{IGNORE_FILE_TYPE}{save}	= 'mw';
$hash{IGNORE_FILE_TYPE}{value}	= 0;

$hash{PROC_DIRS}{save}		= 'mw';
$hash{PROC_DIRS}{value}		= 0;

#############################################################################################
# CLI ONLY OPTIONS

$hash{HTML_HACK}		{save}	= 'norm';
$hash{HTML_HACK}		{value}	= 0;

$hash{browser}			{save}	= 'norm';
$hash{browser}			{value}	= 'elinks';

$hash{editor}			{save}	= 'norm';
$hash{editor}			{value}	= 'vim';

$hash{save_window_size}		{save}	= 'mwg';
$hash{save_window_size}		{value}	= 0;

$hash{window_g}			{save}	= 'mwg';
$hash{window_g}			{value}	= '';

#############################################################################################
# CONFIG DIALOG

$hash{space_character}		{save}	= 'norm';
$hash{space_character}		{value}	= ' ';

$hash{fat32fix}			{save}	= 'norm';
$hash{fat32fix}			{value}	= 0;
$hash{fat32fix}			{value}	= 1 if lc $^O eq 'mswin32';

$hash{file_ext_2_proc}		{save}	= 'norm';
$hash{file_ext_2_proc}		{value}	= "jpeg|jpg|mp3|mpc|mpg|mpeg|avi|asf|wmf|wmv|ogg|ogm|rm|rmvb|mkv";

$hash{debug}			{save}	= 'norm';
$hash{debug}			{value}	= 0;

$hash{LOG_STDOUT}		{save}	= 'norm';
$hash{LOG_STDOUT}		{value}	= 0;

$hash{ERROR_STDOUT}		{save}	= 'norm';
$hash{ERROR_STDOUT}		{value}	= 0;

$hash{ERROR_NOTIFY}		{save}	= 'norm';
$hash{ERROR_NOTIFY}		{value}	= 0;

$hash{ZERO_LOG}			{save}	= 'norm';
$hash{ZERO_LOG}			{value}	= 1;

our $CLI = 0;



# ==============================================================================
# files and arrays


our $killwords_file 	= "$home/.namefix.pl/list_rm_words.txt";
our $killwords_defaults	= "$Bin/data/defaults/killwords.txt";
our @kill_words_arr	= &misc::readf_clean($killwords_defaults);
@kill_words_arr		= &misc::readf_clean($killwords_file) if -f $killwords_file;

our $casing_file    	= "$home/.namefix.pl/list_special_word_casing.txt";
our $casing_defaults   	= "$Bin/data/defaults/special_casing.txt";
our @word_casing_arr	= misc::readf_clean($casing_defaults);
@word_casing_arr	= misc::readf_clean($casing_file) if -f $casing_file;

our $killpat_file   	= "$home/.namefix.pl/list_rm_patterns.txt";
our $killpat_defaults  	= "$Bin/data/defaults/killpatterns.txt";
our @kill_patterns_arr	= &misc::readf_clean($killpat_defaults);
@kill_patterns_arr	= &misc::readf_clean($killpat_defaults) if -f $killpat_file;

our $genres_file	= "$Bin/data/txt/genres.txt";
our @genres		= misc::readf_clean($genres_file);


sub save_hash
{
	&misc::plog(1, "config::save_hash $hash_tsv");
	&misc::null_file($hash_tsv);

	my @types = ('norm', 'mw', 'mwg');

	for my $t (@types)
	{
		&misc::file_append($hash_tsv, "\n######## $t ########\n\n");
		for my $k(sort { $a cmp $b } keys %hash)
		{
			next if $hash{$k}{save} ne $t;
			save_hash_helper($k);
		}
	}
}

sub save_hash_helper
{
	$config::hash{window_g}{value} = $main::mw->geometry if !$CLI;

	my $k = shift;
	if(!defined $hash{$k}{value})
	{
		my $w = "config::save_hash key $k has no value";
		&misc::plog(1, $w);
		print "$w\n$k = \n" . Dumper($hash{$k});
		next;
	}
	&misc::file_append($hash_tsv, "$k\t\t".$hash{$k}{value}."\n");
}


sub load_hash
{
	&misc::plog(1, "config::save_hash $hash_tsv");
	my @tmp = &misc::readf($hash_tsv);
	my %h = ();
	for my $line(@tmp)
	{
		next if $line !~ /.*\t.*/;
		$line =~ s/\n$//;
		$line =~ s/\r$//;
		my ($k, $v) = split(/\t+/, $line);
		$h{$k}{value} = $v;
	}
	for my $k(keys %hash)
	{
		if(!defined $h{$k}{value} || $h{$k}{value} ne '')
		{
			next;
		}
		$hash{$k}{value} = $h{$k}{value};
	}
}

our $folderimage 	= '';
our $fileimage   	= '';

#--------------------------------------------------------------------------------------------------------------
# Save Config File
#--------------------------------------------------------------------------------------------------------------

# MEMO: to self, config file is for stuff under prefs dialog only and defaults is for mainwindow vars
sub save
{
	&save_hash;
}

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

1;
