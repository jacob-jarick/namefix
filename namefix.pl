#!/usr/bin/perl -w

use strict;
use warnings;

use Data::Dumper::Concise;

use English;
use Cwd;
use Carp qw(cluck longmess shortmess);
use File::Find;
use File::Basename qw(&basename &dirname);

use Tk;
use Tk::JPEG;
use Tk::DirTree;
use Tk::Balloon;
use Tk::NoteBook;
use Tk::HList;
use Tk::Radiobutton;
use Tk::Spinbox;
use Tk::Text;
use Tk::ROText;
use Tk::DynaTabFrame;
use Tk::Menu;
use Tk::ProgressBar;

use FindBin qw($Bin);

use lib		"$Bin/libs/";
use lib		"$Bin/libs/gui";

# redirect warnings for Tk::JComboBox
$SIG{'__WARN__'} = sub { warn $_[0] unless (caller eq "Tk::JComboBox"); };
use Tk::JComboBox;

sub quit
{
	my $string = shift;

	$string .= "\n" if $string !~ /\n$/;

	cluck longmess("quit $string\n");
	Tk::exit;
	die "Trying to quit via die";
	print "Trying to quit via CORE::exit";
	CORE::exit;
}
# ----------------------------------------------------------------------------
# Vars
# ----------------------------------------------------------------------------

our $mempic 		= "$Bin/data/mem.jpg";
$config::dir = $ARGV[0];

my $row	= 1;
my $col	= 1;

#--------------------------------------------------------------------------------------------------------------
# mems libs
#--------------------------------------------------------------------------------------------------------------


# mems libs
use misc;
use config;

use fixname;
use run_namefix;
use nf_print;
use dir;
use mp3;
use filter;
use undo;

# gui requires
use dir_hlist;
use about;
use config_dialog;
use blockrename;
use bookmark;
use dialog;
use edit_lists;
use manual;
use menu;
use br_preview;
use undo_gui;

#--------------------------------------------------------------------------------------------------------------
# define any remaining vars - usually vars that require libs loaded
#--------------------------------------------------------------------------------------------------------------

our $log_file = "$config::home/.namefix.pl/namefix.pl.$config::version.log";

#--------------------------------------------------------------------------------------------------------------
# load config file if it exists
#--------------------------------------------------------------------------------------------------------------

&misc::plog(1, "**** namefix.pl $config::version start *************************************************");
&misc::plog(4, "main: \$Bin = \"$Bin\"");

if($^O eq "MSWin32")
{
        $config::fs_fix_default		= 1;
        $config::dialog_font		= "ansi 8 bold";
        $config::dialog_title_font	= "ansi 12 bold";
        $config::edit_pat_font		= "ansi 16 bold";
}
else
{
        $config::fs_fix_default		= 0;
        $config::dialog_font		= "ansi 10";
        $config::dialog_title_font	= "ansi 16 bold";
        $config::edit_pat_font		= "ansi 18 bold";
}

&undo::clear;
&misc::clog		if $config::hash{ZERO_LOG}{value};
&config::load_hash	if -f $config::hash_tsv;

#--------------------------------------------------------------------------------------------------------------
# Begin Gui
#--------------------------------------------------------------------------------------------------------------

our $mw = new MainWindow; # Main Window
$mw -> title("namefix.pl $config::version by Jacob Jarick");

$config::folderimage 	= $main::mw->Getimage('folder');
$config::fileimage   	= $main::mw->Getimage('file');

$mw->bind('<KeyPress>' => sub
{
    if($Tk::event->K eq 'F2')
    {
	$config::testmode = 1;
	if(defined $config::hlist_file && defined $config::hlist_cwd)
	{
		print "Manual Rename '$config::hlist_file' \n";
		&manual::edit($config::hlist_file, $config::hlist_cwd);
	}
    }
    if($Tk::event->K eq 'F5')
    {
	print "refresh\n";
	$config::testmode = 1;
	&dir::ls_dir;
    }
    if($Tk::event->K eq 'F6')
    {
	print "preview\n";
	$config::testmode = 1;
	&run_namefix::run;
    }
    # Escape
    if($Tk::event->K eq 'Escape')
    {
	print "Escape Key = stopping any actions\n";
	$main::STOP = 1;
    }

});
our $balloon = $mw->Balloon();

our $frm_bottom3 = $mw -> Frame()
-> pack
(
	-side => 'bottom',
	-fill => 'x',
	-anchor => 'w'
);

our $frm_bottom2 = $mw -> Frame()
-> pack
(
	-side => 'bottom',
	-fill => 'x',
	-anchor => 'w'
);

our $frm_bottom = $mw -> Frame()
-> pack
(
	-side => 'bottom',
	-fill => 'x',
	-anchor => 'w'
);

my $progress = $frm_bottom2->ProgressBar
(
        -width => 20,
        -from => 0,
        -to => 100,
        -blocks => 50,
        -colors => [0, 'green', 50, 'yellow' , 80, 'red'],
        -variable => \$config::percent_done
)->pack
(
 	-side => "bottom",
	-expand=> 1,
	-fill => "x",
#  	-anchor => 's'
);

# log box
our $log_box = $frm_bottom3->Scrolled
(
	'Text',
	-scrollbars => 'se',
	-background => 'black',
	-foreground => 'white',
	-wrap => 'none',
	-height => 8,
)->pack
(
 	-side => "bottom",
	-expand=> 1,
	-fill => "x",
);
$log_box->Contents();


#--------------------------------------------------------------------------------------------------------------
# Create dynamic tabbed frames for main gui
#--------------------------------------------------------------------------------------------------------------

my $dtfw = 200;
my $dtfh = 460;

my $frame4dtf = $mw->Frame(-width=>$dtfw, -height=>$dtfh)
-> pack(-side => 'left', -fill => 'both', -anchor => 'nw', -fill=>'both');

our $dtf = $frame4dtf->DynaTabFrame
(
	-font => 'Arial 8',
        -raisecolor => 'white',
        -tabcolor => 'grey',
        -tabcurve => 2,
#        -tablock => undef,
        -tabpadx => 3,
        -tabpady => 3,
        -tabrotate => 1,
        -tabside => 'wn',
        -tabscroll => undef,
        -textalign => 1,
        -tiptime => 600,
        -tipcolor => 'yellow',
);

$dtf -> place
(
	-in=>$frame4dtf,
	-relx =>0,
	-rely =>0,
	-width=>$dtfw,
	-height=>$dtfh
);

our $tab7 = $dtf->add
(
	-caption => "TRUN",
	-label => "TRUN",,
	-raisecolor=>'yellow',,
	-tabcolor=>'orange',
	-width=> 300
);

our $tab6 = $dtf->add
(
	-caption => "ENUM",
	-label => "ENUM",
	-raisecolor=>'yellow',,
	-tabcolor=>'orange',
);

our $tab5 = $dtf->add
(
	-caption => "MISC",
	-label => "MISC",
	-raisecolor=>'yellow',,
	-tabcolor=>'orange',
);

our $tab2 = $dtf->add
(
	-caption => "MP3",
	-label => "MP3",
	-raisecolor=>'yellow',,
	-tabcolor=>'orange',
);

our $tab1 = $dtf->add
(
	-caption => "MAIN",
	-label => "MAIN",
	-raisecolor=>'yellow',
	-tabcolor=>'orange',
);

our $frm_left = $tab1 -> Frame()
-> pack
(
	-fill => 'both',
	-expand => 1
);

our $frm_right2 = $mw -> Frame()
-> pack
(
	-side => 'right',
	-expand => 1,
	-fill => 'both'
);

#--------------------------------------------------------------------------------------------------------------
# frame bottom
#--------------------------------------------------------------------------------------------------------------

$col = 1;

my $open_but = $frm_bottom -> Button
(
	-text=>"Browse",
	-activebackground => "cyan",
	-command =>\&dir::dialog
)
-> grid
(
	-row=>1,
	-column=>$col++,
	-sticky=>"nw",
	-padx =>2
);

my $cwd_ent = $frm_bottom->Entry
(
	-textvariable=>\$config::dir,
)
-> grid
(
	-row=>1,
	-column=>$col++,
	-sticky=>"nw",
	-padx =>2
);
$balloon->attach
(
	$cwd_ent,
	-msg => \$config::dir
);

$frm_bottom -> Label()
-> grid
(
	-row=>1,
	-column=>$col++,
	-sticky=>"nw"
);

my $recr_chk = $frm_bottom -> Checkbutton
(
	-text=>"Recursive",
	-variable=>\$config::recr,
	-activeforeground => "blue"
)
-> grid
(
	-row=>1,
	-column=>$col++,
	-sticky=>"nw"
);

my $D_chk = $frm_bottom -> Checkbutton
(
	-text=>"Process Dirs",
	-variable=>\$config::hash{PROC_DIRS}{value},
	-activeforeground => "blue"
)
-> grid
(
	-row=>1,
	-column=>$col++,
	-sticky=>"nw"
);
$balloon->attach
(
	$D_chk,
	-msg => "Process and rename directorys as well.\n\nNote: Use with CAUTION"
);

$frm_bottom -> Label()
-> grid
(
	-row=>1,
	-column=>$col++,
	-sticky=>"nw"
);

my $I_chk = $frm_bottom -> Checkbutton
(
	-text=>"Process ALL Files",
	-variable=>\$config::IGNORE_FILE_TYPE,
	-activeforeground => "blue"
)
-> grid
(
	-row=>1,
	-column=>$col++,
	-sticky=>"nw"
);
$balloon->attach
(
	$I_chk,
	-msg => "Process and rename all files, not just media files."
);

$frm_bottom -> Label
(
	-text=>" "
)
-> grid
(
	-row=>1,
	-column=>$col++,
	-sticky=>"nwe"
);

my $tm_chk = $frm_bottom -> Checkbutton
(
	-text=>"Preview",
	-variable=>\$config::testmode,
	-activeforeground => "blue"
)
-> grid
(
	-row=>1,
	-column=>$col++,
	-sticky=>"nw"
);
$balloon->attach
(
	$tm_chk,
	-msg => "Preview changes that will be made.\n\nNote: This option always re-enables after a run for safety."
);

$frm_bottom -> Label
(
	-text=>" "
)
-> grid
(
	-row=>1,
	-column=>$col++,
	-sticky=>"nwse"
);

$frm_bottom -> Button
(
	-text=>"STOP!",
	-activebackground => "red",
	-command => sub
	{
		if($config::STOP)	# stub
		{
			&misc::plog(1, "namefix.pl: STOP flag allready enabled, turning off LISTING flag as well");
			$config::LISTING = 0;
		}
		$config::STOP = 1;
		$config::RUN = 0;
		$config::testmode = 1;
		&misc::plog(0, "namefix.pl: Stop button pressed");
	}
)
-> grid
(
	-row=>1,
	-column=>$col++,
	-sticky=>"ne"
);

$frm_bottom -> Label
(
	-text=>" "
)
-> grid
(
	-row=>1,
	-column=>$col++,
	-sticky=>"nwse"
);

my $ls_but = $frm_bottom -> Button
(
	-text=>"LIST",
	-activebackground => "orange",
	-command =>\&dir::ls_dir
)
-> grid
(
	-row=>1,
	-column=>$col++,
	-sticky=>"ne"
);

$balloon->attach
(
	$ls_but,
	-msg => "List Directory Contents."
);

$frm_bottom -> Label
(
	-text=>" "
)
-> grid
(
	-row=>1,
	-column=>$col++,
	-sticky=>"ne"
);

$frm_bottom -> Button
(
	-text=>'RUN',
	-activebackground => "green",
	-command =>\&run_namefix::run
)
-> grid
(
	-row=>1,
	-column=>$col++,
	-sticky=>"ne"
);

$frm_bottom -> Label
(
	-text=>" "
)
-> grid
(
	-row=>1,
	-column=>$col++,
	-sticky=>"ne"
);

#--------------------------------------------------------------------------------------------------------------
# main options / tab1 / frame left
#--------------------------------------------------------------------------------------------------------------

$frm_left -> Label
(
	-text=>"Main Options:\n",
	-font => 'Arial 10 bold',
)
-> grid
(
	-row=>1,
	-column=>1,
	-columnspan=>1,
	-sticky=>"nw"
);

my $clean_chk = $frm_left -> Checkbutton
(
	-text=>"General Cleanup",
	-variable=>\$config::hash{CLEANUP_GENERAL}{value},
	-activeforeground => "blue",
	-command=> sub {}
)
-> grid
(
	-row=>2,
	-column=>1,
	-sticky=>"nw"
);
$balloon->attach
(
	$clean_chk,
	-msg => "Preform general cleanups on filename.\n\nNote: Leave on unless doing very specific renaming."
);

my $case_chk = $frm_left -> Checkbutton
(
	-text=>"Normal Casing",
	-variable=>\$config::hash{case}{value},
	-activeforeground => "blue"
)
-> grid
(
	-row=>3,
	-column=>1,
	-sticky=>"nw",
	-columnspan=>2
);
$balloon->attach
(
	$case_chk,
	-msg=>"Uppercase the 1st letter of every word and lowercase the rest"
);

my $w_chk = $frm_left -> Checkbutton
(
	-text=>"Specific Casing",
	-variable=>\$config::hash{WORD_SPECIAL_CASING}{value},
	-activeforeground => "blue"
)
-> grid
(
	-row=>4,
	-column=>1,
	-sticky=>"nw"
);
$balloon->attach
(
	$w_chk,
	-msg => "Applys word specific casing from the \"Specific Casing List\"\n\neg: ABBA, ACDC CD1 CD2 XVII"
);

my $p_chk = $frm_left -> Checkbutton
(
	-text=>"Spaces",
	-variable=>\$config::hash{spaces}{value},
	-activeforeground => "blue"
)
-> grid
(
	-row=>5,
	-column=>1,
	-sticky=>"nw"
);
$balloon->attach
(
	$p_chk,
	-msg => "Swaps space and underscore with the set space delimiter\n\neg: Weezer_-_Hash_Pipe.mp3 to Weezer - Hash Pipe.mp3"
);

my $o_chk = $frm_left -> Checkbutton
(
	-text=>". to Space",
	-variable=>\$config::hash{dot2space}{value},
	-activeforeground => "blue"
)
-> grid
(
	-row=>6,
	-column=>1,
	-sticky=>"nw"
);
$balloon->attach
(
	$o_chk,
	-msg => "Swaps period with the set space delimiter\n\neg: Norther.-.Betrayed.mp3 to Norther - Betrayed.mp3"
);

$frm_left -> Label
(
	-text=>" "
)
-> grid
(
	-row=>8,
	-column=>1,
	-sticky=>"ne"
);

my $K_chk = $frm_left -> Checkbutton
(
	-text=>"RM Word List",
	-variable=>\$config::hash{kill_cwords}{value},
	-activeforeground => "blue"
)
-> grid
(
	-row=>10,
	-column=>1,
	-sticky=>"nw"
);
$balloon->attach
(
	$K_chk,
	-msg => "Remove list of words specified in the \"Remove Word List\""
);

my $P_chk = $frm_left -> Checkbutton
(
	-text=>"RM Pattern List",
	-variable=>\$config::hash{kill_sp_patterns}{value},
	-activeforeground => "blue"
)
-> grid
(
	-row=>11,
	-column=>1,
	-sticky=>"nw"
);
$balloon->attach
(
	$P_chk,
	-msg => "Removes list of regexps specified in \"Remove Pattern List\".\n\nNote: Mainly used to match urls"
);

$frm_left -> Label
(
	-text=>" "
)
-> grid
(
	-row=>12,
	-column=>1,
	-sticky=>"ne"
);

my $R_chk = $frm_left -> Checkbutton
(
	-text=>"Remove:",
	-variable=>\$config::replace,
	-activeforeground => "blue"
)
-> grid
(
	-row=>16,
	-column=>1,
	-sticky=>"nw"
);
$balloon->attach
(
	$R_chk,
	-msg =>
"Remove user entered words\n\nNote 1:\tTo remove multiple words, seperate with |\n\nExample:\tone|two|three\n\nNote 2:\tTo remove | simply escape it like so \\|\nNote 3:\tPerl regexps are available\n\tEnable under File, Preferences, Advance, Enable regexps."
);

my $R_ent1 = $frm_left -> Entry
(
	-textvariable=>\$config::ins_str_old
)
-> grid
(
	-row=>17,
	-column=>1,
	-sticky=>"nw"
);
$balloon->attach
(
	$R_ent1,
	-msg => "Enter word/s to remove"
);

$frm_left -> Label
(
	-text=>"Replace With:"
)
-> grid
(
	-row=>18,
	-column=>1,
	-sticky=>"nw"
);
my $R_ent2 = $frm_left -> Entry
(
	-textvariable=>\$config::ins_str
)
-> grid(
	-row=>19,
	-column=>1,
	-sticky=>"nw"
);
$balloon->attach
(
	$R_ent2,
	-msg => "Leave blank if your only removing words"
);

my $f_chk = $frm_left -> Checkbutton
(
	-text=>"Front Append:",
	-variable=>\$config::INS_START,
	-activeforeground => "blue"
)
-> grid
(
	-row=>20,
	-column=>1,
	-sticky=>"nw"
);
$balloon->attach
(
	$f_chk,
	-msg => "Append string (of characters) to front of filename"
);

my $f_ent = $frm_left -> Entry
(
	-textvariable=>\$config::ins_front_str
)
-> grid
(
	-row=>21,
	-column=>1,
	-sticky=>"nw"
);

my $e_chk = $frm_left -> Checkbutton
(
	-text=>"End Append:",
	-variable=>\$config::end_a,
	-activeforeground => "blue"
)
-> grid
(
	-row=>22,
	-column=>1,
	-sticky=>"nw"
);
$balloon->attach
(
	$e_chk,
	-msg => "Append string to end of filename but before the file extension"
);
my $e_ent = $frm_left -> Entry
(
	-textvariable=>\$config::ins_end_str
)
-> grid
(
	-row=>23,
	-column=>1,
	-sticky=>"nw"
);

my $clr_but = $frm_left -> Button
(
	-text=>"Clear",
	-activebackground => "cyan",
	-command => sub
	{
		&misc::clr_no_save;
		@misc::output = ();
		&misc::plog(1, 'clear');

	}
)
-> grid
(
	-row=>24,
	-column=>1,
	-sticky=>"sw"
);
$balloon->attach
(
	$clr_but,
	-msg => "Reset All options."
);

#--------------------------------------------------------------------------------------------------------------
# id3v2 tab options
#--------------------------------------------------------------------------------------------------------------

$row = 1;

$tab2->Label
(
	-text=>"MP3 Options:\n",
	-font => 'Arial 10 bold',
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>"nw"
);

my $id3_mode_chk = $tab2 -> Checkbutton
(
	-text=>"Process Tags",
	-variable=>\$config::hash{id3_mode}{value},
	-command=>\&dir_hlist::draw_list,
	-activeforeground => "blue"
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>"nw",
	-columnspan=>2
);
$balloon->attach
(
	$id3_mode_chk,
	-msg => "Enable processing of audio file tags"
);

$tab2->Label(-text=>" ")
-> grid
(
	-row=>$row++,
	-column=>1
);

my $id3_guess_tag_chk = $tab2 -> Checkbutton
(
	-text=>"Guess tags",
	-variable=>\$config::hash{id3_guess_tag}{value},
	-activeforeground => "blue"
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>"nw",
	-columnspan=>2
);
$balloon->attach
(
	$id3_guess_tag_chk,
	-msg => "Guess tag from filename\n\nNote: Only works when mp3s are named in 1 of the formats.\n\nTrack Number - Title\nTrack Number - Artist - Title\nArtist - Album - Track Number - Title\nArtist - Track Number - Title\nArtist - Title"
);

my $AUDIO_FORCE_chk = $tab2 -> Checkbutton
(
	-text=>"Overwrite",
	-variable=>\$config::AUDIO_FORCE,
	-activeforeground => "blue"
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>"nw",
	-columnspan=>2
);
$balloon->attach
(
	$AUDIO_FORCE_chk,
	-msg => "Overwrite pre-existing tags when using above option."
);

$tab2->Label(-text=>" ")
-> grid(
	-row=>$row++,
	-column=>1
);

my $rm_id3v2 = $tab2 -> Checkbutton
(
	-text=>"RM id3 tags",
	-variable=>\$config::RM_AUDIO_TAGS,
	-activeforeground => "blue"
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>"nw",
	-columnspan=>2
);


$tab2->Label(-text=>" ")
-> grid(
	-row=>$row++,
	-column=>1
);

my $id3_art_chk = $tab2 -> Checkbutton
(
	-text=>"Set Artist as:",
	-variable=>\$config::AUDIO_SET_ARTIST,
	-activeforeground => "blue"
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>"nw"
);
$balloon->attach
(
	$id3_art_chk,
	-msg => "Set all mp3 artist tags to user entered string."
);

my $id3_art_ent = $tab2 -> Entry
(
	-textvariable=>\$config::id3_art_str
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>"nw"
);

my $id3_alb_chk = $tab2 -> Checkbutton
(
	-text=>"Set Album as:",
	-variable=>\$config::AUDIO_SET_ALBUM,
	-activeforeground => "blue"
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>"nw"
);
$balloon->attach(
	$id3_alb_chk,
	-msg => "Set all mp3 album tags to user entered string."
);

my $id3_alb_ent = $tab2 -> Entry(-textvariable=>\$config::id3_alb_str)
-> grid
(
 	-row=>$row++,
 	-column=>1,
 	-sticky=>"nw"
);


my $id3_genre_chk = $tab2 -> Checkbutton
(
	-text=>"Set Genre as:",
	-variable=>\$config::AUDIO_SET_GENRE,
	-activeforeground => "blue"
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>"nw"
);
$balloon->attach
(
	$id3_genre_chk,
	-msg => "Set all mp3 genre tags to user selection"
);

my $genre_combo = $tab2 -> JComboBox
(
 	-mode=>'readonly',
	-relief=>'groove',
        -background=>'white',
	-textvariable =>\$config::id3_gen_str,
	-choices=>\@config::genres,
        -entrywidth=>16,
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>"nw"
);

# print Dumper(\@config::genres);

my $id3_year_chk = $tab2 -> Checkbutton
(
	-text=>"Set Year as:",
	-variable=>\$config::AUDIO_SET_YEAR,
	-activeforeground => "blue"
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>"nw"
);
$balloon->attach
(
	$id3_year_chk,
	-msg => "Set all mp3 year tags to user entered year."
);

my $id3_year_ent = $tab2 -> Entry
(
	-textvariable=>\$config::id3_year_str
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>"nw"
);

my $id3_com_chk = $tab2 -> Checkbutton
(
	-text=>"Set Comment as:",
	-variable=>\$config::AUDIO_SET_COMMENT,
	-activeforeground => "blue"
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>"nw"
);
$balloon->attach
(
	$id3_com_chk,
	-msg => "Set all mp3 comment tags to user entered string."
);

my $id3_com_ent = $tab2 -> Entry
(
	-textvariable=>\$config::id3_com_str
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>"nw"
);

$tab2 -> Label
(
	-text=>" "
)
->grid
(
	-row=>$row++,
	-column=>1
);

#--------------------------------------------------------------------------------------------------------------
# misc tab options
#--------------------------------------------------------------------------------------------------------------

$tab5 -> Label
(
	-justify=>"left",
	-text=>"Misc Options:\n",
	-font => 'Arial 10 bold',
)
-> grid
(
	-row=>1,
	-column=>1,
	-sticky=>"nw"
);

my $U_chk = $tab5 -> Checkbutton
(
	-text=>"Uppercase All",
	-variable=>\$config::hash{uc_all}{value},
	-activeforeground => "blue",
	-command=> sub { $config::hash{lc_all}{value} = 0 if $config::hash{uc_all}{value}; }
)
-> grid
(
	-row=>2,
	-column=>1,
	-sticky=>"nw"
);

my $L_chk = $tab5 -> Checkbutton
(
	-text=>"Lowercase All",
	-variable=>\$config::hash{lc_all}{value},
	-activeforeground => "blue",
	-command=> sub { $config::hash{uc_all}{value} = 0 if $config::hash{lc_all}{value}; }
)
-> grid
(
	-row=>4,
	-column=>1,
	-sticky=>"nw"
);

my $i_chk = $tab5 -> Checkbutton
(
	-text=>"International",
	-variable=>\$config::hash{intr_char}{value},
	-activeforeground => "blue"
)
-> grid
(
	-row=>8,
	-column=>1,
	-sticky=>"nw"
);
$balloon->attach
(
	$i_chk,
	-msg => "Converts International characters to their English equivalent"
);

my $b_chk = $tab5 -> Checkbutton
(
	-text=>"RM Chars",
	-variable=>\$config::hash{sp_char}{value},
	-activeforeground => "blue"
)
-> grid
(
	-row=>10,
	-column=>1,
	-sticky=>"nw"
);
$balloon->attach
(
	$b_chk,
	-msg => "Removes Following Characters from Filename.\n\n\~ \@ \# \% \( \) \{ \} \[ \] \" \< \> \! \` \' \,"
);

my $d_chk = $tab5 -> Checkbutton
(
	-text=>"RM ^Digits",
	-variable=>\$config::digits,
	-activeforeground => "blue",
	-command=> sub
	{
		if($config::digits == 1)
		{
			$config::rm_digits = 0;
		}
	}
)
-> grid
(
	-row=>14,
	-column=>1,
	-sticky=>"nw"
);
$balloon->attach
(
	$d_chk,
	-msg => "Removes any digits from begining of filename"
);

my $N_chk = $tab5 -> Checkbutton
(
	-text=>"RM all Digits",
	-variable=>\$config::rm_digits,
	-activeforeground => "blue",
	-command=> sub
	{
		if($config::rm_digits == 1)
		{
			$config::digits = 0;
		}
	}
)
-> grid
(
	-row=>16,
	-column=>1,
	-sticky=>"nw"
);

my $tab5_label_scene = $tab5 -> Label
(
	-justify=>"left",
	-text=>"\nScene Options:\n"
)
-> grid
(
	-row=>18,
	-column=>1,
	-sticky=>"nw"
);

my $unscene_chk = $tab5 -> Checkbutton
(
	-text=>"un-Scenify",
	-variable=>\$config::unscene,
	-activeforeground => "blue",
	-command=> sub
	{
		if($config::unscene == 1)
		{
			$config::scene = 0;
		}
	}
)
-> grid(-row=>20, -column=>1, -sticky=>"nw");

$balloon->attach
(
	$unscene_chk,
	-msg => "Converts Season and Episode numbers from scene format to normal format.\n\neg: s10e19 to 10x19"
);

my $scene_chk = $tab5 -> Checkbutton
(
	-text=>"Scenify",
	-variable=>\$config::scene,
	 -activeforeground => "blue",
	 -command=> sub
	 {
	 	if($config::scene == 1)
	 	{
	 		$config::unscene = 0;
	 	}
	 }
)
-> grid
(
	-row=>22,
	-column=>1,
	-sticky=>"nw"
);
$balloon->attach
(
	$scene_chk,
	-msg => "Converts Season and Episode numbers to scene format\n\neg: 01x12 to s01e12"
);

$tab5 -> Label
(
	-justify=>"left",
	-text=>"\nPadding options:\n"
)
-> grid
(
	-row=>24,
	-column=>1,
	-sticky=>"nw"
);

my $pad_chk = $tab5 -> Checkbutton
(
	-text=>"Pad - w space",
	-variable=>\$config::pad_dash,
	-activeforeground => "blue"
)
-> grid
(
	-row=>26,
	-column=>1,
	-sticky=>"nw"
);
$balloon->attach
(
	$pad_chk,
	-msg => "Pads - with user set space delimiter\n\neg: Weird Al-Eat It.mp3 to Weird Al - Eat It.mp3"
);

my $pad_d_chk = $tab5 -> Checkbutton
(
	-text=>"Pad NN w -",
	-variable=>\$config::pad_digits,
	-activeforeground => "blue"
)
-> grid
(
	-row=>28,
	-column=>1,
	-sticky=>"nw"
);
$balloon->attach
(
	$pad_d_chk,
	-msg => "Pads TRACK and SEASONxEPISODE with \" - \"\n\neg: Norther 10 Hollow.mp3 to Norther - 10 - Hollow.mp3"
);

my $pad_d_w_chk = $tab5 -> Checkbutton
(
	-text=>"Pad NxNN w 0",
	-variable=>\$config::pad_digits_w_zero,
	-activeforeground => "blue"
)
-> grid
(
	-row=>30,
	-column=>1,
	-sticky=>"nw"
);
$balloon->attach
(
	$pad_d_w_chk,
	-msg => "Pads SEASONxEPISODE with 0.\n\neg: 1x1, 01x1, 1x01 to 01x01."
);

my $chk_split_dddd = $tab5 -> Checkbutton
(
	-text=>"Pad NNNN with x",
	-variable=>\$config::SPLIT_DDDD,
	-activeforeground => "blue"
)
-> grid
(
	-row=>31,
	-column=>1,
	-sticky=>"nw"
);
$balloon->attach
(
	$chk_split_dddd,
	-msg => "Pads Season and Episode numbers with an x\n\neg:0101 to 01x01, 102 to 1x02"
);

$tab5 -> Label
(
	-text=>""
)
->grid
(
	-row=>32,
	-column=>1
);

#--------------------------------------------------------------------------------------------------------------
# Enumerate Tab
#--------------------------------------------------------------------------------------------------------------

$tab6 -> Label
(
	-text=>"Enumerate Options:\n",
	-font => 'Arial 10 bold',
)
-> grid
(
	-row=>1,
	-column=>1,
	-columnspan=>2,
	-sticky=>"nw"
);

my $n_chk = $tab6 -> Checkbutton
(
	-text=>"Enumerate",
	-variable=>\$config::enum,
	-activeforeground => "blue"
)
-> grid
(
	-row=>2,
	-column=>1,
	-columnspan=>2,
	-sticky=>"nw"
);
$balloon->attach
(
	$n_chk,
	-msg => "Enumerates (Numbers) Files"
);

$tab6 -> Label
(
	-justify=>"left",
	-text=>"\nStyles:\n"
)
-> grid
(
	-row=>3,
	-column=>1,
	-columnspan=>2,
	-sticky=>"nw"
);

my $rdb_a = $tab6 -> Radiobutton
(
	-text=>"Numbers only",
	-value=>"0",
	-variable=>\$config::hash{enum_opt}{value},
	-activeforeground => "blue"
)
-> grid
(
	-row=>4,
	-column=>1,
	-columnspan=>2,
	-sticky=>"nw"
);
my $rdb_b = $tab6 -> Radiobutton
(
	-text=>"Insert at Start",
	-value=>"1",
	-variable=>\$config::hash{enum_opt}{value},
	-activeforeground => "blue"
)
-> grid
(
	-row=>5,
	-column=>1,
	-columnspan=>2,
	-sticky=>"nw"
);
my $rdb_c = $tab6 -> Radiobutton
(
	-text=>"Insert at End",
	-value=>"2",
	-variable=>\$config::hash{enum_opt}{value},
	-activeforeground => "blue"
)
-> grid
(
	-row=>6,
	-column=>1,
	-columnspan=>2,
	-sticky=>"nw"
);

$tab6 -> Label
(
	-justify=>"left",
	-text=>"\nPadding:\n"
)
-> grid
(
	-row=>7,
	-column=>1,
	-columnspan=>2,
	-sticky=>"nw"
);

my $enum_pad_chk = $tab6 -> Checkbutton
(
	-text=>"Pad with zeros",
	-variable=>\$config::hash{enum_pad}{value},
	-activeforeground => "blue"
)
-> grid
(
	-row=>8,
	-column=>1,
	-columnspan=>2,
	-sticky=>"nw"
);
$balloon->attach
(
	$enum_pad_chk,
	-msg => "Pad enumrate number with zeros, so length of digits match length set in spinbox below.\n\neg: 001 Family Pic.jpg"
);

my $spin_pad_enum = $tab6 -> Spinbox
(
	-textvariable=>\$config::hash{enum_pad_zeros}{value},
	-from=>1,
	-to=>1000,
	-increment=>1,
	-width=>8
)
-> grid
(
	-row=>10,
	-column=>1,
	-sticky=>"ne"
);

$tab6 -> Label
(
	-justify=>"left",
	-text=>"zeros"
)
-> grid
(
	-row=>10,
	-column=>2,
	-sticky=>"nw"
);

$tab6 -> Label
(
	-text=>"\n\n\n\n\n\n\n\n\n\n\n"
)
->grid
(
	-row=>22,
	-column=>1
);

#--------------------------------------------------------------------------------------------------------------
# Truncate
#--------------------------------------------------------------------------------------------------------------

$tab7 -> Label
(
	-text=>"Truncate Options:\n",
	-font => 'Arial 10 bold',
)
-> grid
(
	-row=>1,
	-column=>1,
	-columnspan=>1,
	-sticky=>"nw"
);

my $trunc_chk = $tab7 -> Checkbutton
(
	-text=>"Truncate",
	-variable=>\$config::truncate,
	-activeforeground => "blue"
)
-> grid
(
	-row=>2,
	-column=>1,
	-columnspan=>1,
	-sticky=>"nw"
);
$balloon->attach
(
	$trunc_chk,
	-msg => "Truncate filenames using settings below"
);

$tab7 -> Label
(
	-justify=>"left",
	-text=>"\nFilename Length: "
)
-> grid
(
	-row=>3,
	-column=>1,
	-sticky=>"nw"
);

my $tfl_ent = $tab7 -> Entry
(
	-textvariable=>\$config::hash{'truncate_to'}{'value'},
)
-> grid
(
	-row=>4,
	-column=>1,
	-sticky=>"nw"
);
$balloon->attach
(
	$tfl_ent,
	-msg => "Enter the number of characters to truncate to.\n\nNote: Atm this is the same variable as maximum file length\nSo if u save options this number will become the new maximum filelength"
);

$tab7 -> Label
(
	-justify=>"left",
	-text=>"\nStyles:\n"
)
-> grid
(
	-row=>8,
	-column=>1,
	-sticky=>"nw"
);

my $rdb_ts_a = $tab7 -> Radiobutton
(
	-text=>"From Start",
	-value=>"0",
	-variable=>\$config::hash{truncate_style}{value},
	-activeforeground => "blue"
)
-> grid
(
	-row=>10,
	-column=>1,
	-sticky=>"nw"
);
$balloon->attach
(
	$rdb_ts_a,
	-msg => "Remove characters from start of filename."
);

my $rdb_ts_b = $tab7 -> Radiobutton
(
	-text=>"From Middle",
	-value=>"2",
	-variable=>\$config::hash{truncate_style}{value},
	-activeforeground => "blue"
)
-> grid
(
	-row=>11,
	-column=>1,
	-sticky=>"nw"
);
$balloon->attach
(
	$rdb_ts_b,
	-msg => "Remove characters from the middle of the filename."
);
my $rdb_ts_c = $tab7 -> Radiobutton
(
	-text=>"From End",
	-value=>"1",
	-variable=>\$config::hash{truncate_style}{value},
	-activeforeground => "blue"
)
-> grid
(
	-row=>12,
	-column=>1,
	-sticky=>"nw"
);
$balloon->attach
(
	$rdb_ts_c,
	-msg => "Remove characters from end of filename."
);

my $tab7_spacer1 = $tab7 -> Label
(
	-text=>" "
)
-> grid
(
	-row=>13,
	-column=>1,
	-sticky=>"nw"
);

$tab7 -> Label
(
	-justify=>"left",
	-text=>"Insert Character\/s: "
)
-> grid
(
	-row=>14,
	-column=>1,
	-columnspan=>1,
	-sticky=>"nw"
);

my $tab7_trunc_ent = $tab7 -> Entry
(
	-textvariable=>\$config::hash{trunc_char}{value},
)
-> grid
(
	-row=>15,
	-column=>1,
	-columnspan=>1,
	-sticky=>"nw"
);
$balloon->attach
(
	$tab7_trunc_ent,
	-msg => "Enter one or more characters to be placed\nin the middle of each file truncated using the\ntruncate from middle style.\n\nleave blank to have nothing put in."
);

$tab7 -> Label
(
	-text=>"\n\n\n\n\n\n\n\n\n\n"
)
->grid
(
	-row=>22,
	-column=>1
);


#--------------------------------------------------------------------------------------------------------------
# draw filter
#--------------------------------------------------------------------------------------------------------------

our $f_frame = $main::frm_right2->Frame()
-> pack
(
        -side=>"top",

);

$f_frame -> Checkbutton
(
	-text=>"Filter",
	-variable=>\$config::hash{FILTER}{value},
	-activeforeground => "blue",
        -command=> sub
	{
		if($config::hash{FILTER}{value} && $main::filter_string eq "")	# dont enable filter on an empty string
		{
			&misc::plog(1, "namefix: tried to enable filtering with an empty filter");
			$config::hash{FILTER}{value} = 0;
		}
		else
		{
			&dir::ls_dir;
		}
	}
)
->pack
(
	-side=>'left',
);


$f_frame->Label(-text=>" ")->pack(-side=>'left',);

$f_frame->Entry
(
        -textvariable=>\$main::filter_string,
        -width=>35
)
->pack(-side=>'left',);

$f_frame -> Checkbutton
(
	-text=>"Case Sensitive",
	-variable=>\$config::hash{FILTER_IGNORE_CASE}{value},
	-activeforeground => "blue"
)
->pack(	-side=>'left',);

$f_frame -> Checkbutton
(
	-text=>"Use RE",
	-variable=>\$config::hash{FILTER_REGEX}{value},
	-activeforeground => "blue"
)
->pack
(
	-side=>'left',
);

#--------------------------------------------------------------------------------------------------------------
# No more frames
#--------------------------------------------------------------------------------------------------------------

if($config::hash{window_g}{value} ne "")
{
	$mw ->geometry($config::hash{window_g}{value});
}

&menu::draw;
# &dir_hlist::draw_list;
&dir::ls_dir;
MainLoop;


#--------------------------------------------------------------------------------------------------------------
# End
#--------------------------------------------------------------------------------------------------------------

sub callback
{
    print "\n";
    print "callback args  = @_\n";
    print "\$Tk::event     = $Tk::event\n";
    print "\$Tk::widget    = $Tk::widget\n";
    print "\$Tk::event->W  = ", $Tk::event->W, "\n";
}
