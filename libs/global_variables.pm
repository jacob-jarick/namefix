our $load_defaults 	= 0;
our $fs_fix_default = 0;
our $OVERWRITE	= 0;
$dir = cwd if !$dir;
our $cwd		= $dir;
our $hlist_cwd		= $cwd;

# File locations
our $fonts_file		= "$home/.namefix.pl/fonts.ini";
our $bookmark_file	= "$home/.namefix.pl/list_bookmarks.txt";
our $undo_cur_file	= "$home/.namefix.pl/undo.current.filenames.txt";
our $undo_pre_file	= "$home/.namefix.pl/undo.previous.filenames.txt";
our $undo_dir_file	= "$home/.namefix.pl/undo.dir.txt";

# system internal vars

our $hlist_file		= '';
our $hlist_file_new	= '';
our $hlist_newfile_row	= 0;
our $hlist_file_row	= 1;
our $testmode 		= 1;
our $change 		= 0;
our $id3_writeme	= 0;	# used for missing id3v1/id3v2 that can be filled in from each other
our $suggestF 		= 0;	# suggest using fsfix var
our $tmpfilefound 	= 0;
our $tmpfilelist 	= "";
our $enum_count 	= 0;
our $last_recr_dir 	= "";
our $delay		= 3;		# delay
our $update_delay	= $main::delay;	# initial value

# internal flags
# note: its been my decision that all internal flags will be in UC
# should make the app more c like (I hope), and if not its still tidier.

our $FIRST_DIR_LISTED	= 0;
our $BR_DONE		= 0;	# a block rename has occured
our $MR_DONE		= 0;	# a manual rename has occured
our $FILTER		= 0;	# filter flag, to be used for main gui in future - atm just used in block renaming
our $LOG_STDOUT		= 0;
our $UNDO		= 0;
our $case 		= 1;
our $truncate_style 	= 0;
our $scene 		= 0;
our $unscene		= 0;
our $rm_digits		= 0;
our $digits     	= 0;
our $pad_dash 		= 0;
our $pad_digits 	= 0;
our $pad_digits_w_zero	= 0;
our $truncate		= 0;
our $uc_all		= 0;
our $lc_all		= 0;
our $replace		= 0;
our $ins_str		= "";
our $recr		= 0;

1;
