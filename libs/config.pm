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

our $version 			= '4.1.12';
our $folderimage 		= '';
our $fileimage   		= '';

$hash{debug}			{save}		= 'base';
$hash{debug}			{default}	= 0;
$hash{debug}			{value}		= 0;
$hash{debug}			{type}		= 'int';

$hash{log_stdout}		{save}		= 'base';
$hash{log_stdout}		{default}	= 0;
$hash{log_stdout}		{value}		= 0;
$hash{log_stdout}		{type}		= 'bool';

$hash{error_stdout}		{save}		= 'base';
$hash{error_stdout}		{default}	= 1;
$hash{error_stdout}		{value}		= 1;
$hash{error_stdout}		{type}		= 'bool';

$hash{error_notify}		{save}		= 'base';
$hash{error_notify}		{default}	= 1;
$hash{error_notify}		{value}		= 1;
$hash{error_notify}		{type}		= 'bool';

$hash{zero_log}			{save}		= 'base';
$hash{zero_log}			{default}	= 1;
$hash{zero_log}			{value}		= 1;
$hash{zero_log}			{type}		= 'bool';

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
our $exif_rm			= 0;	# counter for number of exif data removed
our @find_arr			= ();
our $tmpfilelist 		= '';
our $last_recr_dir 		= '';

our $hash_tsv			= &misc::get_home."/.namefix.pl/config_hash.tsv";

our @id3v2_exts 		= ('aac', 'aiff', 'ape', 'flac', 'm4a', 'mp2', 'mp3', 'mp4', 'mpc', 'ogg', 'opus', 'wma');
our $id3_ext_regex 		= join('|', @id3v2_exts);

our @exif_exts = 
(
	'3fr', 'arw', 'bmp', 'cr2', 'cr3', 'crw', 'dcr', 'dng', 'erf', 'gif', 
	'heic', 'heif', 'jpeg', 'jpg', 'kdc', 'mef', 'mos', 'mrw', 'nef', 'nrw', 
	'orf', 'pef', 'png', 'raf', 'raw', 'rw2', 'sr2', 'srf', 'tif', 'tiff', 
	'x3f'
);

#############################################################################################
# MAIN TAB

$hash{cleanup_general}		{save}		= 'extended';
$hash{cleanup_general}		{default}	= 0;
$hash{cleanup_general}		{value}		= 0;
$hash{cleanup_general}		{type}		= 'bool';

$hash{case}					{save}		= 'extended';
$hash{case}					{default}	= 0;
$hash{case}					{value}		= 0;
$hash{case}					{type}		= 'bool';

$hash{word_special_casing}	{save}		= 'extended';
$hash{word_special_casing}	{default}	= 0;
$hash{word_special_casing}	{value}		= 0;
$hash{word_special_casing}	{type}		= 'bool';

$hash{spaces}				{save}		= 'extended';
$hash{spaces}				{default}	= 0;
$hash{spaces}				{value}		= 0;
$hash{spaces}				{type}		= 'bool';

$hash{dot2space}			{save}		= 'extended';
$hash{dot2space}			{default}	= 0;
$hash{dot2space}			{value}		= 0;
$hash{dot2space}			{type}		= 'bool';

$hash{kill_cwords}			{save}		= 'extended';
$hash{kill_cwords}			{default}	= 0;
$hash{kill_cwords}			{value}		= 0;
$hash{kill_cwords}			{type}		= 'bool';

$hash{kill_sp_patterns}		{save}		= 'extended';
$hash{kill_sp_patterns}		{default}	= 0;
$hash{kill_sp_patterns}		{value}		= 0;
$hash{kill_sp_patterns}		{type}		= 'bool';

$hash{replace}				{save}		= 'no';
$hash{replace}				{default}	= 0;
$hash{replace}				{value}		= 0;
$hash{replace}				{type}		= 'bool';

$hash{ins_end}				{save}		= 'no';
$hash{ins_end}				{default}	= 0;
$hash{ins_end}				{value}		= 0;
$hash{ins_end}				{type}		= 'bool';

$hash{ins_start}			{save}		= 'no';
$hash{ins_start}			{default}	= 0;
$hash{ins_start}			{value}		= 0;
$hash{ins_start}			{type}		= 'bool';

# String variables for remove/replace/append operations (never saved)
$hash{ins_str_old}			{save}		= 'no';
$hash{ins_str_old}			{default}	= '';
$hash{ins_str_old}			{value}		= '';
$hash{ins_str_old}			{type}		= 'str';

$hash{ins_str}				{save}		= 'no';
$hash{ins_str}				{default}	= '';
$hash{ins_str}				{value}		= '';
$hash{ins_str}				{type}		= 'str';

$hash{ins_front_str}		{save}		= 'no';
$hash{ins_front_str}		{default}	= '';
$hash{ins_front_str}		{value}		= '';
$hash{ins_front_str}		{type}		= 'str';

$hash{ins_end_str}			{save}		= 'no';
$hash{ins_end_str}			{default}	= '';
$hash{ins_end_str}			{value}		= '';
$hash{ins_end_str}			{type}		= 'str';

# ID3 tag string variables (never saved)
$hash{id3_art_str}			{save}		= 'no';
$hash{id3_art_str}			{default}	= '';
$hash{id3_art_str}			{value}		= '';
$hash{id3_art_str}			{type}		= 'str';

$hash{id3_alb_str}			{save}		= 'no';
$hash{id3_alb_str}			{default}	= '';
$hash{id3_alb_str}			{value}		= '';
$hash{id3_alb_str}			{type}		= 'str';

$hash{id3_tra_str}			{save}		= 'no';
$hash{id3_tra_str}			{default}	= '';
$hash{id3_tra_str}			{value}		= '';
$hash{id3_tra_str}			{type}		= 'str';

$hash{id3_tit_str}			{save}		= 'no';
$hash{id3_tit_str}			{default}	= '';
$hash{id3_tit_str}			{value}		= '';
$hash{id3_tit_str}			{type}		= 'str';

$hash{id3_gen_str}			{save}		= 'no';
$hash{id3_gen_str}			{default}	= 'Metal';
$hash{id3_gen_str}			{value}		= 'Metal';
$hash{id3_gen_str}			{type}		= 'str';

$hash{id3_year_str}			{save}		= 'no';
$hash{id3_year_str}			{default}	= '';
$hash{id3_year_str}			{value}		= '';
$hash{id3_year_str}			{type}		= 'str';

$hash{id3_com_str}			{save}		= 'no';
$hash{id3_com_str}			{default}	= '';
$hash{id3_com_str}			{value}		= '';
$hash{id3_com_str}			{type}		= 'str';

# Legacy GUI variable - kept for compatibility but also in hash
$hash{end_a}				{save}		= 'no';
$hash{end_a}				{default}	= 0;
$hash{end_a}				{value}		= 0;
$hash{end_a}				{type}		= 'bool';



#############################################################################################
# MP3 TAB

$hash{id3_mode}				{save}		= 'extended';
$hash{id3_mode}				{default}	= 0;
$hash{id3_mode}				{value}		= 0;
$hash{id3_mode}				{type}		= 'bool';

$hash{id3_guess_tag}		{save}		= 'extended';
$hash{id3_guess_tag}		{default}	= 0;
$hash{id3_guess_tag}		{value}		= 0;
$hash{id3_guess_tag}		{type}		= 'bool';

$hash{id3_force}			{save}		= 'extended';
$hash{id3_force}			{default}	= 0;
$hash{id3_force}			{value}		= 0;
$hash{id3_force}			{type}		= 'bool';

$hash{id3_tags_rm}		{save}		= 'no';
$hash{id3_tags_rm}		{default}	= 0;
$hash{id3_tags_rm}		{value}		= 0;
$hash{id3_tags_rm}		{type}		= 'bool';

$hash{id3_set_artist}		{save}		= 'no';
$hash{id3_set_artist}		{default}	= 0;
$hash{id3_set_artist}		{value}		= 0;
$hash{id3_set_artist}		{type}		= 'bool';

$hash{id3_set_album}		{save}		= 'no';
$hash{id3_set_album}		{default}	= 0;
$hash{id3_set_album}		{value}		= 0;
$hash{id3_set_album}		{type}		= 'bool';

$hash{id3_set_genre}		{save}		= 'no';
$hash{id3_set_genre}		{default}	= 0;
$hash{id3_set_genre}		{value}		= 0;
$hash{id3_set_genre}		{type}		= 'bool';

$hash{id3_set_year}		{save}		= 'no';
$hash{id3_set_year}		{default}	= 0;
$hash{id3_set_year}		{value}		= 0;
$hash{id3_set_year}		{type}		= 'bool';

$hash{id3_set_comment}	{save}		= 'no';
$hash{id3_set_comment}	{default}	= 0;
$hash{id3_set_comment}	{value}		= 0;
$hash{id3_set_comment}	{type}		= 'bool';

# (ID3 tag strings now defined in hash above with save='no')

#############################################################################################
# MISC TAB

$hash{uc_all}				{save}		= 'extended';
$hash{uc_all}				{default}	= 0;
$hash{uc_all}				{value}		= 0;
$hash{uc_all}				{type}		= 'bool';

$hash{lc_all}				{save}		= 'extended';
$hash{lc_all}				{default}	= 0;
$hash{lc_all}				{value}		= 0;
$hash{lc_all}				{type}		= 'bool';

$hash{intr_char}			{save}		= 'extended';
$hash{intr_char}			{default}	= 0;
$hash{intr_char}			{value}		= 0;
$hash{intr_char}			{type}		= 'bool';

$hash{c7bit}				{save}		= 'extended';
$hash{c7bit}				{default}	= 0;
$hash{c7bit}				{value}		= 0;
$hash{c7bit}				{type}		= 'bool';

$hash{sp_char}				{save}		= 'extended';
$hash{sp_char}				{default}	= 0;
$hash{sp_char}				{value}		= 0;
$hash{sp_char}				{type}		= 'bool';

$hash{rm_digits}			{save}		= 'extended'; #	RM ^Digits
$hash{rm_digits}			{default}	= 0;
$hash{rm_digits}			{value}		= 0;
$hash{rm_digits}			{type}		= 'bool';

$hash{digits}				{save}		= 'extended';
$hash{digits}				{default}	= 0;
$hash{digits}				{value}		= 0;
$hash{digits}				{type}		= 'bool';

$hash{unscene}				{save}		= 'extended';
$hash{unscene}				{default}	= 0;
$hash{unscene}				{value}		= 0;
$hash{unscene}				{type}		= 'bool';

$hash{scene}				{save}		= 'extended';
$hash{scene}				{default}	= 0;
$hash{scene}				{value}		= 0;
$hash{scene}				{type}		= 'bool';

$hash{pad_N_to_NN}			{save}		= 'extended';
$hash{pad_N_to_NN}			{default}	= 0;
$hash{pad_N_to_NN}			{value}		= 0;
$hash{pad_N_to_NN}			{type}		= 'bool';

$hash{pad_dash}				{save}		= 'extended';
$hash{pad_dash}				{default}	= 0;
$hash{pad_dash}				{value}		= 0;
$hash{pad_dash}				{type}		= 'bool';

$hash{pad_digits}			{save}		= 'extended';
$hash{pad_digits}			{default}	= 0;
$hash{pad_digits}			{value}		= 0;
$hash{pad_digits}			{type}		= 'bool';

$hash{pad_digits_w_zero}	{save}		= 'extended';
$hash{pad_digits_w_zero}	{default}	= 0;
$hash{pad_digits_w_zero}	{value}		= 0;
$hash{pad_digits_w_zero}	{type}		= 'bool';

$hash{split_dddd}			{save}		= 'extended';
$hash{split_dddd}			{default}	= 0;
$hash{split_dddd}			{value}		= 0;
$hash{split_dddd}			{type}		= 'bool';

#############################################################################################
# ENUMURATE TAB

$hash{enum}				{save}		= 'extended';
$hash{enum}				{default}	= 0;
$hash{enum}				{value}		= 0;
$hash{enum}				{type}		= 'bool';

$hash{enum_opt}			{save}		= 'extended';
$hash{enum_opt}			{default}	= 0;
$hash{enum_opt}			{value}		= 0;
$hash{enum_opt}			{type}		= 'bool';

$hash{enum_add}			{save}		= 'extended';
$hash{enum_add}			{default}	= 0;
$hash{enum_add}			{value}		= 0;
$hash{enum_add}			{type}		= 'bool';

$hash{enum_pad}			{save}		= 'extended';
$hash{enum_pad}			{default}	= 0;
$hash{enum_pad}			{value}		= 0;
$hash{enum_pad}			{type}		= 'bool';

$hash{enum_pad_zeros}	{save}		= 'extended';
$hash{enum_pad_zeros}	{default}	= 4;
$hash{enum_pad_zeros}	{value}		= 4;
$hash{enum_pad_zeros}	{type}		= 'int';

$hash{enum_start_str}	{save}		= 'no';
$hash{enum_start_str}	{default}	= '';
$hash{enum_start_str}	{value}		= '';
$hash{enum_start_str}	{type}		= 'str';

$hash{enum_end_str}		{save}		= 'no';
$hash{enum_end_str}		{default}	= '';
$hash{enum_end_str}		{value}		= '';
$hash{enum_end_str}		{type}		= 'str';

#############################################################################################
# TRUNCATE TAB

$hash{truncate}			{save}		= 'extended';
$hash{truncate}			{default}	= 0;
$hash{truncate}			{value}		= 0;
$hash{truncate}			{type}		= 'bool';

$hash{truncate_to}		{save}		= 'extended';
$hash{truncate_to}		{default}	= 256;
$hash{truncate_to}		{value}		= 256;
$hash{truncate_to}		{type}		= 'int';

$hash{truncate_style}	{save}		= 'extended';
$hash{truncate_style}	{default}	= 0;
$hash{truncate_style}	{value}		= 0;
$hash{truncate_style}	{type}		= 'int';

$hash{trunc_char}		{save}		= 'extended';
$hash{trunc_char}		{default}	= '';
$hash{trunc_char}		{value}		= '';
$hash{trunc_char}		{type}		= 'str';

#############################################################################################
# EXIF TAB

$hash{exif_show}		{save}		= 'extended';
$hash{exif_show}		{default}	= 0;
$hash{exif_show}		{value}		= 0;
$hash{exif_show}		{type}		= 'bool';

$hash{exif_rm_all}		{save}		= 'extended';
$hash{exif_rm_all}		{default}	= 0;
$hash{exif_rm_all}		{value}		= 0;
$hash{exif_rm_all}		{type}		= 'bool';

#############################################################################################
# FILTER BAR

$hash{filter}				{save}		= 'extended';
$hash{filter}				{default}	= 0;
$hash{filter}				{value}		= 0;
$hash{filter}				{type}		= 'bool';

$hash{filter_ignore_case}	{save}		= 'extended';
$hash{filter_ignore_case}	{default}	= 0;
$hash{filter_ignore_case}	{value}		= 0;
$hash{filter_ignore_case}	{type}		= 'bool';

our $filter_string	= '';

#############################################################################################
# bottom menu bar

$hash{recursive}		{save}			= 'base';
$hash{recursive}		{default}		= 0;
$hash{recursive}		{value}			= 0;
$hash{recursive}		{type}			= 'bool';

$hash{ignore_file_type}	{save}			= 'extended';
$hash{ignore_file_type}	{default}		= 0;
$hash{ignore_file_type}	{value}			= 0;
$hash{ignore_file_type}	{type}			= 'bool';

$hash{proc_dirs}		{save}			= 'extended';
$hash{proc_dirs}		{default}		= 0;
$hash{proc_dirs}		{value}			= 0;
$hash{proc_dirs}		{type}			= 'bool';

#############################################################################################
# CLI ONLY OPTIONS

$hash{html_hack}		{save}		= 'base';
$hash{html_hack}		{default}	= 0;
$hash{html_hack}		{value}		= 0;
$hash{html_hack}		{type}		= 'bool';

$hash{browser}			{save}		= 'base';
$hash{browser}			{default}	= 'elinks';
$hash{browser}			{value}		= 'elinks';
$hash{browser}			{type}		= 'str';

$hash{editor}			{save}		= 'base';
$hash{editor}			{default}	= 'vim';
$hash{editor}			{value}		= 'vim';
$hash{editor}			{type}		= 'str';

# Additional CLI-only options from help that weren't in GUI
$hash{undo}				{save}		= 'base';
$hash{undo}				{default}	= 0;
$hash{undo}				{value}		= 0;
$hash{undo}				{type}		= 'bool';

$hash{save_options}		{save}		= 'base';
$hash{save_options}		{default}	= 0;
$hash{save_options}		{value}		= 0;
$hash{save_options}		{type}		= 'bool';

#############################################################################################
# CONFIG DIALOG - MAIN TAB

$hash{space_character}		{save}		= 'base';
$hash{space_character}		{default}	= ' ';
$hash{space_character}		{value}		= ' ';
$hash{space_character}		{type}		= 'str';

$hash{max_fn_length}		{save}		= 'base';
$hash{max_fn_length}		{default}	= 256;
$hash{max_fn_length}		{value}		= 256;
$hash{max_fn_length}		{type}		= 'int';

$hash{save_window_size}		{save}		= 'base';
$hash{save_window_size}		{default}	= 0;
$hash{save_window_size}		{value}		= 0;
$hash{save_window_size}		{type}		= 'bool';

$hash{window_g}				{save}		= 'geometry';
$hash{window_g}				{default}	= '';
$hash{window_g}				{value}		= '';
$hash{window_g}				{type}		= 'str';

our $save_extended			= 0;	# save main window options

#############################################################################################
# CONFIG DIALOG - ADVANCED TAB

$hash{fat32fix}				{save}		= 'base';
$hash{fat32fix}				{default}	= 0;
$hash{fat32fix}				{default}	= 1 if lc $^O eq 'mswin32';
$hash{fat32fix}				{value}		= $hash{fat32fix}{default};
$hash{fat32fix}				{type}		= 'bool';

$hash{filter_regex}			{save}		= 'base';
$hash{filter_regex}			{default}	= 0;
$hash{filter_regex}			{value}		= 0;
$hash{filter_regex}			{type}		= 'bool';

$hash{file_ext_2_proc}		{save}		= 'base';
$hash{file_ext_2_proc}		{default}	= "aac|aiff|ape|asf|avi|bmp|flac|gif|jpeg|jpg|m4a|m4v|mkv|mov|mp2|mp3|mp4|mpc|mpg|mpeg|ogg|ogm|opus|png|rm|rmvb|svg|tif|tiff|webm|webp|wma|wmv";
$hash{file_ext_2_proc}		{value}		= $hash{file_ext_2_proc}{default};
$hash{file_ext_2_proc}		{type}		= 'str';

$hash{overwrite}			{save}		= 'base';
$hash{overwrite}			{default}	= 0;
$hash{overwrite}			{value}		= 0;
$hash{overwrite}			{type}		= 'bool';

$hash{remove_regex}			{save}		= 'base';
$hash{remove_regex}			{default}	= 0;
$hash{remove_regex}			{value}		= 0;
$hash{remove_regex}			{type}		= 'bool';

#############################################################################################
# CONFIG DIALOG - DEBUG TAB

$hash{debug}			{save}		= 'base';
$hash{debug}			{default}	= 2;
$hash{debug}			{value}		= 2;
$hash{debug}			{type}		= 'int';

$hash{log_stdout}		{save}		= 'base';
$hash{log_stdout}		{default}	= 0;
$hash{log_stdout}		{value}		= 0;
$hash{log_stdout}		{type}		= 'bool';

$hash{error_stdout}		{save}		= 'base';
$hash{error_stdout}		{default}	= 0;
$hash{error_stdout}		{value}		= 0;
$hash{error_stdout}		{type}		= 'bool';

$hash{error_notify}		{save}		= 'base';
$hash{error_notify}		{default}	= 0;
$hash{error_notify}		{value}		= 0;
$hash{error_notify}		{type}		= 'bool';

$hash{zero_log}			{save}		= 'base';
$hash{zero_log}			{default}	= 1;
$hash{zero_log}			{value}		= 1;
$hash{zero_log}			{type}		= 'bool';


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

	# $config::hash{id3_tags_rm}		{value} = 0;
	# $config::hash{id3_force}		{value} = 0;

	# $config::hash{id3_set_artist}	{value} = 0;
	# $config::hash{id3_set_album}	{value} = 0;
	# $config::hash{id3_set_genre}	{value} = 0;
	# $config::hash{id3_set_year}		{value} = 0;
	# $config::hash{id3_set_comment}	{value} = 0;

	# $config::hash{id3_guess_tag}	{value} = 0;

	# $config::hash{id3_art_str}		{value} = '';
	# $config::hash{id3_alb_str}		{value} = '';
	# $config::hash{id3_gen_str}		{value} = '';
	# $config::hash{id3_year_str}		{value} = '';
	# $config::hash{id3_com_str}		{value} = '';
}

1;

