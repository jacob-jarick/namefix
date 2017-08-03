#!/usr/bin/perl -w

use strict;
use warnings;

use Data::Dumper::Concise;

use English;
use Cwd;
use MP3::Tag;
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

# ----------------------------------------------------------------------------
# Vars
# ----------------------------------------------------------------------------

my $row	= 1;
my $col	= 1;

our $id3v2_rm;
our $id3_guess_tag;
our $id3_year_str;
our $LISTING;
our $truncate;
our $eaw;
our $id3_year_set;
our $ig_type;
our $truncate_to;
our $pad_digits_w_zero;
our $faw;
our $id3_art_str;
our $id3_alb_set;
our $rpwnew;
our $case;
our $intr_char;
our $id3_com_str;
our $enum_pad_zeros;
our $id3v1_rm;
our $rpwold;
our $pad_digits;
our $kill_cwords;
our $FILTER_REGEX;
our $pad_dash;
our $id3_com_set;
our $recr;
our $filter_cs;
our $end_a;
our $id3_gen_str;
our $kill_sp_patterns;
our $split_dddd;
our $id3_mode;
our $id3_art_set;
our $author;
our $spaces;
our $testmode;
our $id3_force_guess_tag;
our $enum_pad;
our $dot2space;
our $trunc_char;
our $ZERO_LOG;
our $proc_dirs;
# our $sp_word;
our $id3_alb_str;
our $replace;
our $enum;
our $genres;
our $id3_gen_set;
our $sp_char;
our $front_a;

our $percent_done = 0;
our $WORD_SPECIAL_CASING;

#--------------------------------------------------------------------------------------------------------------
# mems libs
#--------------------------------------------------------------------------------------------------------------


# mems libs
use fixname;
use run_namefix;
use misc;
require "$Bin/libs/global_variables.pm";
use config;

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

&undo::clear;

#--------------------------------------------------------------------------------------------------------------
# load config file if it exists
#--------------------------------------------------------------------------------------------------------------


if(-f $main::config_file)
{
	do $main::config_file;	# executes config file
}

if(-f $main::fonts_file)
{
	do $main::fonts_file;		# if font file exists
}

&config_dialog::save_fonts;

if($main::ZERO_LOG)
{
	&misc::clog;
}

&misc::plog(1, "**** namefix.pl $main::version start *************************************************");
&misc::plog(4, "main: \$Bin = \"$Bin\"");

&config::load_hash;

#--------------------------------------------------------------------------------------------------------------
# Begin Gui
#--------------------------------------------------------------------------------------------------------------

our $mw = new MainWindow; # Main Window
$mw -> title("namefix.pl $main::version by $main::author");

$mw->bind('<KeyPress>' => sub
{
    print 'Keysym=', $Tk::event->K, ', numeric=', $Tk::event->N, "\n";

    if($Tk::event->K eq 'F2')
    {
	$testmode = 1;
	if(defined $main::hlist_file && defined $main::hlist_cwd)
	{
		print "Manual Rename '$main::hlist_file' \n";
		&main::manual_edit($main::hlist_file, $main::hlist_cwd);
	}
    }
    if($Tk::event->K eq 'F5')
    {
	print "refresh\n";
	$testmode = 1;
	&dir::ls_dir;
    }
    if($Tk::event->K eq 'F6')
    {
	print "preview\n";
	$testmode = 1;
	&run_namefix::run;
    }
    # Escape
    if($Tk::event->K eq 'Escape')
    {
	print "Escape Key = stopping any actions\n";
	$main::STOP = 1;
    }

});

our $folderimage 	= $mw->Getimage("folder");
our $fileimage   	= $mw->Getimage("file");

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
        -variable => \$percent_done
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
# 	-insertmode => "insert",
)->pack
(
 	-side => "bottom",
	-expand=> 1,
	-fill => "x",
#  	-anchor => 's'
);
$log_box->Contents();


#--------------------------------------------------------------------------------------------------------------
# Create dynamic tabbed frames for main gui
#--------------------------------------------------------------------------------------------------------------

my $dtfw = 200;
my $dtfh = 460;

my $frame4dtf = $mw->Frame(-width=>$dtfw, -height=>$dtfh)
-> pack(-side => 'left', -fill => 'both', -anchor => 'nw', -fill=>'both');

our $dtf = $frame4dtf->DynaTabFrame (
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
	-command =>\&dir_dialog
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
	-textvariable=>\$main::dir,
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
	-msg => \$main::dir
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
	-variable=>\$main::recr,
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
	-variable=>\$main::proc_dirs,
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
	-variable=>\$main::ig_type,
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
	-variable=>\$main::testmode,
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
		if($main::STOP)	# stub
		{
			&misc::plog(1, "namefix.pl: STOP flag allready enabled, turning off LISTING flag as well");
			$main::LISTING = 0;
		}
		$main::STOP = 1;
		$main::RUN = 0;
		$main::testmode = 1;
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
	-text=>"RUN",
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
	-variable=>\$main::cleanup,
	-activeforeground => "blue",
	-command=> sub {
		if($main::cleanup == 0)
		{
			$main::advance = 1;
		}
		else
		{
			$main::advance = 0;
		}
	}
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
	-variable=>\$main::case,
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
	-variable=>\$main::WORD_SPECIAL_CASING,
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
	-variable=>\$main::spaces,
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
	-variable=>\$main::dot2space,
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
	-variable=>\$main::kill_cwords,
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
	-variable=>\$main::kill_sp_patterns,
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
	-variable=>\$main::replace,
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
	-textvariable=>\$main::rpwold
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
	-textvariable=>\$main::rpwnew
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
	-variable=>\$main::front_a,
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
	-textvariable=>\$main::faw
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
	-variable=>\$main::end_a,
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
	-textvariable=>\$main::eaw
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
	-command =>\&clr_no_save
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
# id3v1 tab options
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
	-variable=>\$main::id3_mode,
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
	-msg => "Enable processing of id3v1 and id3v2 tags"
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
	-variable=>\$main::id3_guess_tag,
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

my $id3_force_guess_tag_chk = $tab2 -> Checkbutton
(
	-text=>"Overwrite",
	-variable=>\$main::id3_force_guess_tag,
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
	$id3_force_guess_tag_chk,
	-msg => "Overwrite pre-existing tags when using above option."
);

$tab2->Label(-text=>" ")
-> grid(
	-row=>$row++,
	-column=>1
);

my $rm_id3v1 = $tab2 -> Checkbutton
(
	-text=>"RM id3v1 tags",
	-variable=>\$main::id3v1_rm,
	-activeforeground => "blue"
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>"nw",
	-columnspan=>2
);

my $rm_id3v2 = $tab2 -> Checkbutton
(
	-text=>"RM id3v2 tags",
	-variable=>\$id3v2_rm,
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
	-variable=>\$main::id3_art_set,
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
	-textvariable=>\$main::id3_art_str
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
	-variable=>\$main::id3_alb_set,
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

my $id3_alb_ent = $tab2 -> Entry(
	-textvariable=>\$main::id3_alb_str
)
-> grid(
 	-row=>$row++,
 	-column=>1,
 	-sticky=>"nw"
);


my $id3_genre_chk = $tab2 -> Checkbutton
(
	-text=>"Set Genre as:",
	-variable=>\$main::id3_gen_set,
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
	-textvariable =>\$main::id3_gen_str,
	-choices=>\@main::genres,
        -entrywidth=>16,
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>"nw"
);

# print Dumper(\@main::genres);

my $id3_year_chk = $tab2 -> Checkbutton
(
	-text=>"Set Year as:",
	-variable=>\$main::id3_year_set,
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
	-textvariable=>\$main::id3_year_str
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
	-variable=>\$main::id3_com_set,
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
	-textvariable=>\$main::id3_com_str
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
	-variable=>\$main::uc_all,
	-activeforeground => "blue",
	-command=> sub
	{
		if($main::uc_all == 1)
		{
			$main::lc_all = 0;
		}
	}
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
	-variable=>\$main::lc_all,
	-activeforeground => "blue",
	-command=> sub
	{
		if($main::lc_all == 1)
		{
			$main::uc_all = 0;
		}
	}
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
	-variable=>\$main::intr_char,
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
	-variable=>\$main::sp_char,
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
	-variable=>\$main::digits,
	-activeforeground => "blue",
	-command=> sub
	{
		if($main::digits == 1)
		{
			$main::rm_digits = 0;
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
	-variable=>\$main::rm_digits,
	-activeforeground => "blue",
	-command=> sub
	{
		if($main::rm_digits == 1)
		{
			$main::digits = 0;
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
	-variable=>\$main::unscene,
	-activeforeground => "blue",
	-command=> sub
	{
		if($main::unscene == 1)
		{
			$main::scene = 0;
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
	-variable=>\$main::scene,
	 -activeforeground => "blue",
	 -command=> sub
	 {
	 	if($main::scene == 1)
	 	{
	 		$main::unscene = 0;
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
	-variable=>\$main::pad_dash,
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
	-variable=>\$main::pad_digits,
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
	-variable=>\$main::pad_digits_w_zero,
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
	-variable=>\$main::split_dddd,
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
	-variable=>\$main::enum,
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
	-variable=>\$main::enum_opt,
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
	-variable=>\$main::enum_opt,
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
	-variable=>\$main::enum_opt,
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
	-variable=>\$main::enum_pad,
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
	-textvariable=>\$main::enum_pad_zeros,
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
	-variable=>\$main::truncate,
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
	-textvariable=>\$main::truncate_to,
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
	-variable=>\$main::truncate_style,
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
	-variable=>\$main::truncate_style,
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
	-variable=>\$main::truncate_style,
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
	-textvariable=>\$main::trunc_char,
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
	-variable=>\$main::FILTER,
	-activeforeground => "blue",
        -command=> sub
	{
		if($main::FILTER && $main::filter_string eq "")	# dont enable filter on an empty string
		{
			&misc::plog(1, "namefix: tried to enable filtering with an empty filter");
			$main::FILTER = 0;
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


$f_frame->Label
(
	-text=>" "
)
->pack
(
	-side=>'left',
);

$f_frame->Entry
(
        -textvariable=>\$main::filter_string,
        -width=>35
)
->pack
(
	-side=>'left',
);

$f_frame -> Checkbutton
(
	-text=>"Case Sensitive",
	-variable=>\$main::filter_cs,
	-activeforeground => "blue"
)
->pack
(
	-side=>'left',
);

$f_frame -> Checkbutton
(
	-text=>"Use RE",
	-variable=>\$main::FILTER_REGEX,
	-activeforeground => "blue"
)
->pack
(
	-side=>'left',
);

#--------------------------------------------------------------------------------------------------------------
# No more frames
#--------------------------------------------------------------------------------------------------------------

if($main::window_g ne "")
{
	$mw ->geometry($main::window_g);
}

&menu::draw;
&dir_hlist::draw_list;
MainLoop;


#--------------------------------------------------------------------------------------------------------------
# End
#--------------------------------------------------------------------------------------------------------------

sub callback {
    print "\n";
    print "callback args  = @_\n";
    print "\$Tk::event     = $Tk::event\n";
    print "\$Tk::widget    = $Tk::widget\n";
    print "\$Tk::event->W  = ", $Tk::event->W, "\n";
}
