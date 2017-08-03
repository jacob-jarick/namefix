# global variables

# variables that need to be declacred 1st
# for use with home directory and os dependant variables

our $version 		= "4.1.2";
our $author 		= "Jacob Jarick";
our $debug		= "0";

# DEBUG LEVELS - WIP
# 0 = log always - important errors etc
# 1
# 2
# 3 = print subnames etc
# 4 = print details of sub

our $load_defaults 	= 0;
our $config_version  	= "";

our $dir = $ARGV[0];
our $home = "";
our $fs_fix_default = 0;

our $OVERWRITE	= 0;

# Detect enviroment and setup namefix directories

our $nf_dir = $Bin."/";

if(!$dir)
{
        $dir = cwd;
}

if($^O eq "MSWin32")
{
        $home = $ENV{"USERPROFILE"};
        $fs_fix_default		= 1;
        our $dialog_font	= "ansi 8 bold";
        our $dialog_title_font	= "ansi 12 bold";
        our $edit_pat_font	= "ansi 16 bold";
        our $dir_slash		= "\\";
}
else
{
        $fs_fix_default = 0;
        $home = $ENV{"HOME"},
        our $dialog_font	= "ansi 10";
        our $dialog_title_font	= "ansi 16 bold";
        our $edit_pat_font	= "ansi 18 bold";
        our $dir_slash		= "\/";
}

if(!$home)
{
        $home = $ENV{"TMP"};    # surely the os has a tmp if nothing else
}

if(!-d "$home/.namefix.pl")
{
        mkdir("$home/.namefix.pl", 0755) || die "Cannot mkdir :$home/.namefix.pl $!\n";
}

# File locations

our $config_file	= "$home/.namefix.pl/config.ini";
our $fonts_file		= "$home/.namefix.pl/fonts.ini";
# our $bm_pl		= "$home/.namefix.pl/bm.ini";
our $log_file		= "$home/.namefix.pl/logfile.txt";
our $casing_file    	= "$home/.namefix.pl/list_special_word_casing.txt";
our $killwords_file 	= "$home/.namefix.pl/list_rm_words.txt";
our $killpat_file   	= "$home/.namefix.pl/list_rm_patterns.txt";
our $bookmark_file	= "$home/.namefix.pl/list_bookmarks.txt";
our $changelog		= "$Bin/txt/changelog.txt";
our $about		= "$Bin/txt/about.txt";
our $todo		= "$Bin/txt/todo.txt";
our $thanks		= "$Bin/txt/thanks.txt";
our $links		= "$Bin/txt/links.txt";

our $namefix_log_file	= "$home/.namefix.pl/namefix.pl"."$version"."log";
our $namefix_error_file	= "$home/.namefix.pl/namefix.pl"."$version"."error.log";

our $mempic 		= $nf_dir."mem.jpg";

our $html_file		= "$home/.namefix.pl/namefix_html_output_hack.html";

our $undo_cur_file	= "$home/.namefix.pl/undo.current.filenames.txt";
our $undo_pre_file	= "$home/.namefix.pl/undo.previous.filenames.txt";
our $undo_dir_file	= "$home/.namefix.pl/undo.dir.txt";

our $browser		= "elinks";
our $editor		= "vim";

# system internal vars

our $cwd		= $dir;
our $hlist_cwd		= $cwd;
our $hlist_file		= "";
our $hlist_file_new	= "";
our $hlist_newfile_row	= 0;
our $hlist_file_row	= 1;
our $testmode 		= 1;
our $change 		= 0;
our $id3_change		= 0;	# counter for changes made 2 id3 tags
our $tags_rm		= 0;	# counter for number of tags removed
our $id3_writeme	= 0;	# used for missing id3v1/id3v2 that can be filled in from each other
our $suggestF 		= 0;	# suggest using fsfix var
our $tmpfilefound 	= 0;
our $tmpfilelist 	= "";
our $enum_count 	= 0;
our $rpwold_escaped	= "";
our $last_recr_dir 	= "";
our $hl_counter		= 0;
our @bm_arr 		= "";	# bookmark array
our $bm_menu_hash	= "";
our $bm_count		= 0;
our $hlist_selection	= 0;	# current line selected

our $delay		= 3;		# delay
our $update_delay	= $main::delay;	# initial value

# internal flags
# note: its been my decision that all internal flags will be in UC
# should make the app more c like (I hope), and if not its still tidier.

our $RUN		= 0;
our $STOP		= 0;
our $LISTING		= 0;
our $FIRST_DIR_LISTED	= 0;
our $BR_DONE		= 0;	# a block rename has occured
our $MR_DONE		= 0;	# a manual rename has occured
our $FILTER		= 0;	# filter flag, to be used for main gui in future - atm just used in block renaming
our $ERROR_NOTIFY	= 0;
our $ERROR_STDOUT	= 1;
our $LOG_STDOUT		= 0;
our $ZERO_LOG		= 1;
our $HTML_HACK		= 0;
our $UNDO		= 0;

our $SAVE_WINDOW_SIZE	= 0;

our $CLI		= 0;

# filter options

our $filter_string		= "";
our $FILTER_REGEX		= 0;
our $filter_cs			= 0;

# preference options - save enabled

our $cleanup		= 1;
our $case 		= 1;
our $advance		= 0;
our $space_character 	= " ";
our $max_fn_length 	= 256;
our $truncate_to    	= $max_fn_length;

our $id3_guess_tag	= 0;
our $id3_force_guess_tag	= 0;
our $id3_mode		= 0;

our $window_g		= "";

our $fat32fix 		= $fs_fix_default;
our $file_ext_2_proc 	= "jpeg|jpg|mp3|mpc|mpg|mpeg|avi|asf|wmf|wmv|ogg|ogm|rm|rmvb|mkv";

our $enum_opt		= 1;
our $enum_pad		= 1;
our $enum_pad_zeros 	= "4";
$enum_pad_zeros		= 4;

our $truncate_style 	= 0;
our $trunc_char		= "";


# main window options - save enabled

$main::WORD_SPECIAL_CASING	= 0;
our $spaces			= 1;
our $dot2space			= 0;
our $intr_char 			= 0;
our $kill_cwords	 	= 0;
our $kill_sp_patterns 		= 0;
our $sp_char			= 0;

# main window, misc options - no save allowed

our $scene 		= 0;
our $unscene		= 0;

our $rm_digits		= 0;
our $digits     	= 0;

our $pad_dash 		= 0;
our $pad_digits 	= 0;
our $pad_digits_w_zero	= 0;

# main window options - no save allowed

our $enum		= 0;	# enumerate mode
our $truncate		= 0;
our $uc_all		= 0;
our $lc_all		= 0;

our $replace		= 0;
our $rpwold		= "";
our $rpwnew		= "";

our $front_a 		= 0;
our $faw		= "";
our $end_a 		= 0;
our $eaw		= "";

our $recr		= 0;
our $proc_dirs  	= 0;
our $ig_type 		= 0;

# main window, id3 tag vars

our $id3_art_set	= 0;
our $id3_art_str	= "";

our $id3_alb_set	= 0;
our $id3_alb_str	= "";

our $id3_com_set	= 0;
our $id3_com_str	= "";

our $id3v1_rm		= 0;
our $id3v2_rm		= 0;

$main::id3_gen_set 	= 0;
$main::id3_gen_str 	= "Metal";

$main::id3_year_set 	= 0;
$main::id3_year_str 	= "";

$main::split_dddd	= 0;

our @undo_cur	= ();	# undo array - current filenames
our @undo_pre	= ();	# undo array - previous filenames

our @find_arr	= ();

our $undo_dir	= "";	# directory to preform undo in

# all prefined arrays.

# Kill Common Words array, for safety reasons all are case specific.
@main::kill_words_arr =
(
        # net sites
        'ShareReactor',
        'ShareConnector',
        'Sharevirus',
        'English.[www.tvu.org.ru]',
	'[www.tvu.org.ru]',
	'[tvu.org.ru]',

        # misc
	'2HD',
        'ac3',
        'divx',
        'dsrip',
        'DVDrip',
        'DVDscr',
	'DVD',
        'hdtv',
        'HDRip',
	'preair',
	'SATRip',
        'tv',
        'WS',		# wide screen
        'xvid',

        # mp3/divx/xvid Ripper tags
	'0TV',
	'aaf',
	'aXXo',		# love your rips man
	'BayHarborButcher',
	'Bia',
	'bsgtv',
	'Caph',
        'Crimson',
        'DMT',
        'DiAMOND',
	'Dvsky',
        'Saphire',
        'FoV',
	'FQM',
	'Gnarly',
	'klaxxon',
        'LoL',
        'LoKi',
        'l0ki',
	'[Moonsong]',
        'pdtv',
        'rns',
        'VFUA',
        'VTV',
        'dsr',
        'tcm',
        'fqm',
        'notv',
        'kyr',
        'aaf',
        'xor',
        'ctu',
        'repack',
	'OMiCRON',
        'orenji',
        'sdtv',
	'STFU',
	'sys',
        'tvd',
        '2sd'
);
@main::kill_words_arr_escaped = ();

# Big Word Casing List

# Douglas: Thanks to the great folk at karanet for the help with the following list!
# ( ssh bbs@karanet.uni-klu.ac.at )

@main::word_casing_arr =
(
        'ABBA', 'ABC', 'AC', 'ACDC', 'ATC',
        'BSB',
        'CIA', 'CNN',
        'CD', 'CD1', 'CD2', 'CD3', 'CD4',
        'DNA', 'DC', 'DJ', 'DVD', 'DVDRip', 'DivX', 'DVDA',
        'FBI', 'FM',
        'II', 'III', 'IV',
        'KGB',
        'LSD',
        'MadTV', 'MASH', 'MTV', 'MIB',
        'NIN',
        'OK', 'OST', 'OVA',
        'USSR', 'USA',
        'REM',
        'STS', 'SNK', 'SG-1',
        'TV', 'THC', 'TimTim', 'TNT',
        'UK',
        'vs', 'VI', 'VII', 'VII',
        'YMCA',
        'XXX', 'Xvid', 'IX', 'XI', 'XII', 'XIII', 'XIV', 'XV', 'XVI', 'XVII', 'XVIII',
        'a', 'an', 'at', 'and', 'are', 'for', 'in', 'is', 'it', 'of', 'on', 'the', 'to',
        '- A', '- At', '- An', '- And', 'Are', '- For', '- In', '- Is', '- It', '- Of', '- On', '- The', '- To'
);

# @main::word_casing_arr_escaped = @main::word_casing_arr; # default list does not need escaping

@main::kill_patterns_arr =
(
        '(\(|\[)(divx|dvdrip|dvd|tv|xvid)(\]|\))',
	'(\(|\[)(www\..*?|)\.(com|net|de|tk|ru|nl)(\]|\))',
	'(\[|\()(\]|\))',
	'(\[[a-f0-9]*\])'
);

@main::genres =
(
	"A Capella", "Acid", "Acid Jazz", "Acid Punk", "Acoustic", "Alt. Rock", "Alternative", "Ambient", "Anime", "Avantgarde",
	"Ballad", "Bass", "Beat", "Bebob", "Big Band", "Black Metal", "Bluegrass", "Blues", "Booty Bass", "BritPop",
	"Cabaret", "Celtic", "Chamber Music", "Chanson", "Chorus", "Christian Gangsta Rap", "Christian Rap", "Christian Rock", "Classic Rock", "Classical", "Club", "Club-House", "Comedy", "Contemporary Christian", "Country", "Crossover", "Cult",
	"Dance", "Dance Hall", "Darkwave", "Death Metal", "Disco", "Dream", "Drum & Bass", "Drum Solo", "Duet",
	"Easy Listening", "Electronic", "Ethnic", "Euro-House", "Euro-Techno", "Eurodance",
	"Folk", "Folk/Rock", "Folklore", "Freestyle", "Funk", "Fusion", "Fusion",
	"Game", "Gangsta", "Goa", "Gospel", "Gothic", "Gothic Rock", "Grunge",
	"Hard Rock", "Hardcore", "Heavy Metal", "Hip-Hop", "House", "Humour",
	"Indie", "Industrial", "Instrum. Pop", "Instrum. Rock", "Instrumental",
	"Jazz", "Jazz+Funk", "Jpop", "Jungle",
	"Latin", "Lo-Fi",
	"Meditative", "Merengue", "Metal", "Musical",
	"National Folk", "Native American", "Negerpunk", "New Age", "New Wave", "Noise",
	"Oldies", "Opera", "Other", "Polka", "Polsk Punk", "Pop", "Pop-Folk", "Pop/Funk", "Porn Groove", "Power Ballad", "Pranks", "Primus", "Progress. Rock", "Psychadel. Rock", "Psychadelic", "Punk", "Punk Rock",
	"R&B", "Rap", "Rave", "Reggae", "Retro", "Revival", "Rhythmic Soul", "Rock", "Rock & Roll",
	"Salsa", "Samba", "Satire", "Showtunes", "Ska", "Slow Jam", "Slow Rock", "Sonata", "Soul", "Sound Clip", "Soundtrack", "Southern Rock", "Space", "Speech", "Swing", "Symphonic Rock", "Symphony", "Synthpop",
	"Tango", "Techno", "Techno-Indust.", "Terror", "Thrash Metal", "Top 40", "Trailer", "Trance", "Tribal", "Trip-Hop",
	"Vocal"
);


1;
