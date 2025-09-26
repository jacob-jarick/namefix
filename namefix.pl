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
# Try to load Tk::JPEG but don't fail if it's not available
eval { require Tk::JPEG; };
our $HAS_JPEG = !$@;
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
use Tk::Text::SuperText;

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

	print "\n\n====================================================================================\n\n";

	cluck longmess("quit $string\n");
	Tk::exit;
	die "Trying to quit via die";
	print "Trying to quit via CORE::exit";
	CORE::exit;
}
#--------------------------------------------------------------------------------------------------------------
# mems libs
#--------------------------------------------------------------------------------------------------------------

# mems libs
use misc;
use config;
use log;
use style;

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

$config::dir = $ARGV[0] if defined $ARGV[0];


#--------------------------------------------------------------------------------------------------------------
# load config file if it exists
#--------------------------------------------------------------------------------------------------------------

&misc::plog(1, "**** namefix.pl $config::version start *************************************************");
&misc::plog(4, "main: \$Bin = \"$Bin\"");

if(lc $^O eq 'mswin32')
{
        $config::dialog_font		= 'ansi 8 bold';
        $config::dialog_title_font	= 'ansi 12 bold';
        $config::edit_pat_font		= 'ansi 16 bold';
}
else
{
        $config::dialog_font		= 'ansi 10';
        $config::dialog_title_font	= 'ansi 16 bold';
        $config::edit_pat_font		= 'ansi 18 bold';
}

&misc::clog		if $config::hash{ZERO_LOG}{value};

if (-f $config::hash_tsv)
{
	&config::load_hash;
}
else
{
	print "didnt find config file: $config::hash_tsv\n";
}

#--------------------------------------------------------------------------------------------------------------
# Begin Gui
#--------------------------------------------------------------------------------------------------------------
my $row	= 1;
my $col	= 1;

our $mw = new MainWindow; # Main Window
$mw -> title("namefix.pl $config::version by Jacob Jarick");

$config::folderimage 	= $main::mw->Getimage('folder');
$config::fileimage   	= $main::mw->Getimage('file');

$mw->bind('<KeyPress>' => sub
{
	if($Tk::event->K eq 'F2')
	{
		$config::PREVIEW = 1;
		if(defined $config::hlist_file && defined $config::hlist_cwd)
		{
			print "Manual Rename '$config::hlist_file' \n";
			&manual::edit($config::hlist_file, $config::hlist_cwd);
		}
	}
	if($Tk::event->K eq 'F5')
	{
		print "refresh\n";
		$config::PREVIEW = 1;
		&dir::ls_dir;
	}
	if($Tk::event->K eq 'F6')
	{
		print "preview\n";
		$config::PREVIEW = 1;
		&run_namefix::run;
	}
	# Escape
	if($Tk::event->K eq 'Escape')
	{
		print "Escape Key = stopping any actions\n";
		&config::halt;
	}

	# Help - TODO
	if($Tk::event->K eq 'F1')
	{
		print "Hello\n";
	}

});
our $balloon = $mw->Balloon();

our $frm_bottom3 = $mw -> Frame()
-> pack
(
	-side=>		'bottom',
	-fill=>		'x',
	-anchor=>	'w'
);

our $frm_bottom2 = $mw -> Frame()
-> pack
(
	-side=>		'bottom',
	-fill=>		'x',
	-anchor=>	'w'
);

our $frm_bottom = $mw -> Frame()
-> pack
(
	-side=>		'bottom',
	-fill=>		'x',
	-anchor=>	'w'
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
 	-side=>		'bottom',
	-expand=>	1,
	-fill=>		'x',
);

# log box
our $log_box = $frm_bottom3->Scrolled
(
	'SuperText',
	-scrollbars=>	'se',
	-background=>	'black',
	-foreground=>	'white',
	-wrap=>		'none',
	-height=>	8,
)->pack
(
 	-side=>		'bottom',
	-expand=>	1,
	-fill=>		'x',
);
$log_box->Contents();

# Tie the log file to the log box
our $log_file_pos;
$log_file_pos = -s $main::log_file if -f $main::log_file; # Get initial size
$log_file_pos = 0 if !defined $log_file_pos;

sub tail_log_file
{
    if (-f $main::log_file)
    {
        open my $fh, '<', $main::log_file or return;
        seek $fh, $log_file_pos, 0;
        while (my $line = <$fh>)
        {
            $main::log_box->insert('end', $line);
            $main::log_box->see('end');
        }
        $log_file_pos = tell $fh;
        close $fh;
    }
    # Reschedule the next check
    $main::mw->after(1000, \&tail_log_file);
}
# Start the first check
$main::mw->after(1000, \&tail_log_file);

#--------------------------------------------------------------------------------------------------------------
# Create dynamic tabbed frames for main gui
#--------------------------------------------------------------------------------------------------------------

my $dtfw = 200;
my $dtfh = 460;

my $frame4dtf = $mw->Frame(-width=>$dtfw, -height=>$dtfh)
-> pack(-side => 'left', -fill => 'both', -anchor => 'nw', -fill=>'both');

our $dtf = $frame4dtf->DynaTabFrame
(
	-font=>		'Arial 8',	# TODO set this from config
        -raisecolor=>	'white',
        -tabcolor=>	'grey',
        -tabcurve=>	2,
        -tabpadx=>	3,
        -tabpady=>	3,
        -tabrotate=>	1,
        -tabside=>	'wn',
        -tabscroll=>	undef,
        -textalign=>	1,
        -tiptime=>	600,
        -tipcolor=>	'yellow',
);

$dtf -> place
(
	-in=>		$frame4dtf,
	-relx=>		0,
	-rely=>		0,
	-width=>	$dtfw,
	-height=>	$dtfh
);

our $tab7 = $dtf->add
(
	-caption=>	'TRUN',
	-label=>	'TRUN',
	-raisecolor=>	'yellow',
	-tabcolor=>	'orange',
	-width=>	300
);

our $tab6 = $dtf->add
(
	-caption=>	'ENUM',
	-label=>	'ENUM',
	-raisecolor=>	'yellow',
	-tabcolor=>	'orange',
);

our $tab5 = $dtf->add
(
	-caption=>	'MISC',
	-label=>	'MISC',
	-raisecolor=>	'yellow',
	-tabcolor=>	'orange',
);

our $tab2 = $dtf->add
(
	-caption=>	'MP3',
	-label=>	'MP3',
	-raisecolor=>	'yellow',
	-tabcolor=>	'orange',
);

our $tab1 = $dtf->add
(
	-caption=>	'MAIN',
	-label=>	'MAIN',
	-raisecolor=>	'yellow',
	-tabcolor=>	'orange',
);

our $frm_left = $tab1 -> Frame()
-> pack
(
	-fill=>		'both',
	-expand=>	1
);

our $frm_right2 = $mw -> Frame()
-> pack
(
	-side=>		'right',
	-expand=>	1,
	-fill=>		'both'
);

#--------------------------------------------------------------------------------------------------------------
# frame bottom
#--------------------------------------------------------------------------------------------------------------

$col = 1;

my $open_but = $frm_bottom -> Button
(
	-text=>			'Browse',
	-activebackground=>	'cyan',
	-command=>		\&dir::dialog
)
-> grid
(
	-row=>		1,
	-column=>	$col++,
	-sticky=>	'nw',
	-padx=>		2
);

my $cwd_ent = $frm_bottom->Entry(-textvariable=>\$config::dir, -width=>0)
-> grid
(
	-row=>		1,
	-column=>	$col++,
	-sticky=>	'nw',
	-padx=>		2
);
$balloon->attach($cwd_ent, -msg => \$config::dir);

$frm_bottom -> Label()
-> grid
(
	-row=>		1,
	-column=>	$col++,
	-sticky=>	'nw'
);

my $recr_chk = $frm_bottom -> Checkbutton
(
	-text=>			'Recursive',
	-variable=>		\$config::hash{RECURSIVE}{value},
	-activeforeground=>	'blue'
)
-> grid
(
	-row=>		1,
	-column=>	$col++,
	-sticky=>	'nw'
);

my $D_chk = $frm_bottom -> Checkbutton
(
	-text=>			'Process Dirs',
	-variable=>		\$config::hash{PROC_DIRS}{value},
	-activeforeground=>	'blue'
)
-> grid
(
	-row=>	1,
	-column=>	$col++,
	-sticky=>	'nw'
);
$balloon->attach($D_chk, -msg=> "Process and rename directorys as well.\n\nNote: Use with CAUTION");

$frm_bottom->Label()
-> grid
(
	-row=>1,
	-column=>$col++,
	-sticky=>'nw'
);

my $I_chk = $frm_bottom->Checkbutton
(
	-text=>			'Process ALL Files',
	-variable=>		\$config::hash{IGNORE_FILE_TYPE}{value},
	-activeforeground=>	'blue'
)
-> grid
(
	-row=>		1,
	-column=>	$col++,
	-sticky=>	'nw'
);
$balloon->attach
(
	$I_chk,
	-msg => 'Process and rename all files, not just media files'
);

$frm_bottom -> Label(-text=>' ')
-> grid
(
	-row=>		1,
	-column=>	$col++,
	-sticky=>	'nwe'
);

my $tm_chk = $frm_bottom -> Checkbutton
(
	-text=>			'Preview',
	-variable=>		\$config::PREVIEW,
	-activeforeground=>	'blue'
)
-> grid
(
	-row=>		1,
	-column=>	$col++,
	-sticky=>	'nw'
);
$balloon->attach
(
	$tm_chk,
	-msg => "Preview changes that will be made.\n\nNote: This option always re-enables after a run for safety."
);

$frm_bottom->Label(-text=>' ')
-> grid
(
	-row=>		1,
	-column=>	$col++,
	-sticky=>	'nwse'
);

$frm_bottom -> Button
(
	-text=>			'STOP!',
	-activebackground=>	'red',
	-command=>
	sub
	{
		if($config::STOP)	# stub
		{
			&misc::plog(1, "namefix.pl: STOP flag already enabled, turning off LISTING flag as well");
			$config::LISTING = 0;
		}
		&config::halt;
		&misc::plog(0, "namefix.pl: Stop button pressed");
	}
)
-> grid
(
	-row=>		1,
	-column=>	$col++,
	-sticky=>	'ne'
);

$frm_bottom -> Label(-text=>' ')
-> grid
(
	-row=>		1,
	-column=>	$col++,
	-sticky=>	'nwse'
);

my $ls_but = $frm_bottom -> Button
(
	-text=>			'LIST',
	-activebackground=>	'orange',
	-command=>		\&dir::ls_dir
)
-> grid
(
	-row=>		1,
	-column=>	$col++,
	-sticky=>	'ne'
);

$balloon->attach($ls_but, -msg=> "List Directory Contents");

$frm_bottom->Label(-text=>' ')
-> grid
(
	-row=>		1,
	-column=>	$col++,
	-sticky=>	'ne'
);

$frm_bottom -> Button
(
	-text=>			'RUN',
	-activebackground=>	'green',
	-command=>		\&run_namefix::run
)
-> grid
(
	-row=>		1,
	-column=>	$col++,
	-sticky=>	'ne'
);

$frm_bottom->Label(-text=>' ')
-> grid
(
	-row=>		1,
	-column=>	$col++,
	-sticky=>	'ne'
);

#--------------------------------------------------------------------------------------------------------------
# main options / tab1 / frame left
#--------------------------------------------------------------------------------------------------------------

$row = 1;

$frm_left -> Label
(
	-text=>	"Main Options:\n",
	-font=>	'Arial 10 bold',	# TODO Set from config
)
-> grid
(
	-row=>		$row++,
	-column=>	1,
	-columnspan=>	1,
	-sticky=>	'nw'
);

my $clean_chk = $frm_left->Checkbutton
(
	-text=>			'General Cleanup',
	-variable=>		\$config::hash{CLEANUP_GENERAL}{value},
	-activeforeground=>	'blue',
# 	-command=> sub {}
)
-> grid
(
	-row=>		$row++,
	-column=>	1,
	-sticky=>	'nw'
);
$balloon->attach
(
	$clean_chk,
	-msg => "Perform general cleanups on filename.\n\nNote: Leave on unless doing very specific renaming."
);

my $case_chk = $frm_left -> Checkbutton
(
	-text=>			'Normal Casing',
	-variable=>		\$config::hash{case}{value},
	-activeforeground=>	'blue'
)
-> grid
(
	-row=>		$row++,
	-column=>	1,
	-sticky=>	'nw',
	-columnspan=>	2
);
$balloon->attach
(
	$case_chk,
	-msg=>"Uppercase the 1st letter of every word and lowercase the rest"
);

my $w_chk = $frm_left -> Checkbutton
(
	-text=>			'Specific Casing',
	-variable=>		\$config::hash{WORD_SPECIAL_CASING}{value},
	-activeforeground=>	'blue'
)
-> grid
(
	-row=>		$row++,
	-column=>	1,
	-sticky=>	'nw'
);
$balloon->attach
(
	$w_chk,
	-msg => "Applies word specific casing from the \"Specific Casing List\"\n\neg: ABBA, ACDC CD1 CD2 XVII"
);

my $p_chk = $frm_left -> Checkbutton
(
	-text=>			'Spaces',
	-variable=>		\$config::hash{spaces}{value},
	-activeforeground=>	'blue'
)
-> grid
(
	-row=>		$row++,
	-column=>	1,
	-sticky=>	'nw'
);
$balloon->attach
(
	$p_chk,
	-msg => "Swaps space and underscore with the set space delimiter\n\neg: Weezer_-_Hash_Pipe.mp3 to Weezer - Hash Pipe.mp3"
);

my $o_chk = $frm_left -> Checkbutton
(
	-text=>			". to Space",
	-variable=>		\$config::hash{dot2space}{value},
	-activeforeground=>	'blue'
)
-> grid
(
	-row=>		$row++,
	-column=>	1,
	-sticky=>	'nw'
);
$balloon->attach
(
	$o_chk,
	-msg => "Swaps period with the set space delimiter\n\neg: Norther.-.Betrayed.mp3 to Norther - Betrayed.mp3"
);

$frm_left -> Label(-text=>' ')
-> grid
(
	-row=>		$row++,
	-column=>	1,
	-sticky=>	'ne'
);

my $K_chk = $frm_left -> Checkbutton
(
	-text=>			'RM Word List',
	-variable=>		\$config::hash{kill_cwords}{value},
	-activeforeground=>	'blue'
)
-> grid
(
	-row=>		$row++,
	-column=>	1,
	-sticky=>	'nw'
);
$balloon->attach
(
	$K_chk,
	-msg => "Remove list of words specified in the 'Remove Word List'"
);

my $P_chk = $frm_left -> Checkbutton
(
	-text=>			'RM Pattern List',
	-variable=>		\$config::hash{kill_sp_patterns}{value},
	-activeforeground=>	'blue'
)
-> grid
(
	-row=>		$row++,
	-column=>	1,
	-sticky=>	'nw'
);
$balloon->attach
(
	$P_chk,
	-msg => "Removes list of regexps specified in 'Remove Pattern List'.\n\nNote: Mainly used to match urls"
);

$frm_left->Label(-text=>' ')
-> grid
(
	-row=>		$row++,
	-column=>	1,
	-sticky=>	'ne'
);

my $R_chk = $frm_left -> Checkbutton
(
	-text=>			"Remove:",
	-variable=>		\$config::hash{replace}{value},
	-activeforeground=>	'blue'
)
-> grid
(
	-row=>		$row++,
	-column=>	1,
	-sticky=>	'nw'
);
$balloon->attach
(
	$R_chk,
	-msg =>
"Remove user entered words\n\nNote 1:\tTo remove multiple words, separate with |\n\nExample:\tone|two|three\n\nNote 2:\tTo remove | simply escape it like so \\|\nNote 3:\tPerl regexps are available\n\tEnable under File, Preferences, Advance, Enable regexps."
);

my $R_ent1 = $frm_left -> Entry(-textvariable=>\$config::ins_str_old)
-> grid
(
	-row=>		$row++,
	-column=>	1,
	-sticky=>	'nw'
);
$balloon->attach($R_ent1, -msg=> "Enter word/s to remove");

$frm_left -> Label(-text=>"Replace With:")
-> grid
(
	-row=>		$row++,
	-column=>	1,
	-sticky=>	'nw'
);
my $R_ent2 = $frm_left->Entry(-textvariable=>\$config::ins_str)
-> grid
(
	-row=>		$row++,
	-column=>	1,
	-sticky=>	'nw'
);
$balloon->attach($R_ent2, -msg => "Leave blank if your only removing words");

my $f_chk = $frm_left -> Checkbutton
(
	-text=>			"Front Append:",
	-variable=>		\$config::hash{INS_START}{value},
	-activeforeground=>	'blue'
)
-> grid
(
	-row=>		$row++,
	-column=>	1,
	-sticky=>	'nw'
);
$balloon->attach($f_chk, -msg=> "Append string (of characters) to front of filename");

my $f_ent = $frm_left->Entry(-textvariable=>\$config::ins_front_str)
-> grid
(
	-row=>		$row++,
	-column=>	1,
	-sticky=>	'nw'
);

my $e_chk = $frm_left->Checkbutton
(
	-text=>			"End Append:",
	-variable=>		\$config::end_a,
	-activeforeground=>	'blue'
)
-> grid
(
	-row=>		$row++,
	-column=>	1,
	-sticky=>	'nw'
);
$balloon->attach($e_chk, -msg=> "Append string to end of filename but before the file extension");
my $e_ent = $frm_left->Entry(-textvariable=>\$config::ins_end_str)
-> grid
(
	-row=>		$row++,
	-column=>	1,
	-sticky=>	'nw'
);

my $clr_but = $frm_left -> Button
(
	-text=>			"Clear",
	-activebackground=>	"cyan",
	-command=>
	sub
	{
		&misc::clr_no_save;
		&log::clear;
		&misc::plog(2, 'clear');
	}
)
-> grid
(
	-row=>		$row++,
	-column=>	1,
	-sticky=>	'sw'
);
$balloon->attach($clr_but, -msg=> "Reset All options.");

#--------------------------------------------------------------------------------------------------------------
# id3v2 tab options
#--------------------------------------------------------------------------------------------------------------

$row = 1;

$tab2->Label
(
	-text=>	"MP3 Options:\n",
	-font=>	'Arial 10 bold',
)
-> grid
(
	-row=>		$row++,
	-column=>	1,
	-sticky=>	'nw'
);

my $id3_mode_chk = $tab2 -> Checkbutton
(
	-text=>			"Process Tags",
	-variable=>		\$config::hash{id3_mode}{value},
	-command=>		\&dir::ls_dir,
	-activeforeground=>	'blue'
)
-> grid
(
	-row=>		$row++,
	-column=>	1,
	-sticky=>	'nw',
	-columnspan=>	2
);
$balloon->attach($id3_mode_chk, -msg=> "Enable processing of audio file tags");

$tab2->Label(-text=>' ')
-> grid
(
	-row=>$row++,
	-column=>1
);

my $id3_guess_tag_chk = $tab2 -> Checkbutton
(
	-text=>			"Guess tags",
	-variable=>		\$config::hash{id3_guess_tag}{value},
	-activeforeground=>	'blue'
)
-> grid
(
	-row=>		$row++,
	-column=>	1,
	-sticky=>	'nw',
	-columnspan=>	2
);
$balloon->attach
(
	$id3_guess_tag_chk,
	-msg => "Guess tag from filename\n\nNote: Only works when mp3s are named in 1 of the formats.\n\nTrack Number - Title\nTrack Number - Artist - Title\nArtist - Album - Track Number - Title\nArtist - Track Number - Title\nArtist - Title"
);


my $AUDIO_FORCE_chk = $tab2 -> Checkbutton
(
	-text=>"Overwrite",
	-variable=>\$config::hash{AUDIO_FORCE}{value},
	-activeforeground => 'blue'
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>'nw',
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
	-variable=>\$config::hash{RM_AUDIO_TAGS}{value},
	-activeforeground => 'blue'
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>'nw',
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
	-variable=>\$config::hash{AUDIO_SET_ARTIST}{value},
	-activeforeground => 'blue'
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>'nw'
);
$balloon->attach
(
	$id3_art_chk,
	-msg => "Set all mp3 artist tags to user entered string."
);
&main::quit("END found the 0\n") if(defined $config::hash{0});
my $id3_art_ent = $tab2 -> Entry
(
	-textvariable=>\$config::id3_art_str
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>'nw'
);

my $id3_alb_chk = $tab2 -> Checkbutton
(
	-text=>"Set Album as:",
	-variable=>\$config::hash{AUDIO_SET_ALBUM}{value},
	-activeforeground => 'blue'
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>'nw'
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
 	-sticky=>'nw'
);


my $id3_genre_chk = $tab2 -> Checkbutton
(
	-text=>"Set Genre as:",
	-variable=>\$config::hash{AUDIO_SET_GENRE}{value},
	-activeforeground => 'blue'
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>'nw'
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
	-sticky=>'nw'
);


# print Dumper(\@config::genres);

my $id3_year_chk = $tab2 -> Checkbutton
(
	-text=>"Set Year as:",
	-variable=>\$config::hash{AUDIO_SET_YEAR}{value},
	-activeforeground => 'blue'
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>'nw'
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
	-sticky=>'nw'
);

my $id3_com_chk = $tab2 -> Checkbutton
(
	-text=>"Set Comment as:",
	-variable=>\$config::hash{AUDIO_SET_COMMENT}{value},
	-activeforeground => 'blue'
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>'nw'
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
	-sticky=>'nw'
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

my $clr_id3_button = $tab2 -> Button
(
	-text=>"Clear",
	-activebackground => "cyan",
	-command => sub
	{
		$config::hash{id3_guess_tag}		{value} = 0;

		$config::hash{RM_AUDIO_TAGS}		{value} = 0;
		$config::hash{AUDIO_FORCE}		{value} = 0;
		$config::hash{AUDIO_SET_ARTIST}		{value} = 0;
		$config::hash{AUDIO_SET_ALBUM}		{value} = 0;
		$config::hash{AUDIO_SET_GENRE}		{value} = 0;
		$config::hash{AUDIO_SET_YEAR}		{value} = 0;
		$config::hash{AUDIO_SET_COMMENT}	{value} = 0;

		$config::id3_art_str		 = '';
		$config::id3_alb_str		 = '';
		$config::id3_gen_str		 = '';
		$config::id3_year_str		 = '';
		$config::id3_com_str		 = '';

		&misc::plog(2, 'cleared id3 options');
	}
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>"sw"
);
$balloon->attach
(
	$clr_id3_button,
	-msg => "Reset id3 options"
);

#--------------------------------------------------------------------------------------------------------------
# misc tab options
#--------------------------------------------------------------------------------------------------------------

$row = 1;

$tab5 -> Label
(
	-justify=>"left",
	-text=>"Misc Options:\n",
	-font => 'Arial 10 bold',
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>'nw'
);

my $U_chk = $tab5 -> Checkbutton
(
	-text=>"Uppercase All",
	-variable=>\$config::hash{uc_all}{value},
	-activeforeground => 'blue',
	-command=> sub { $config::hash{lc_all}{value} = 0 if $config::hash{uc_all}{value}; }
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>'nw'
);

my $L_chk = $tab5 -> Checkbutton
(
	-text=>"Lowercase All",
	-variable=>\$config::hash{lc_all}{value},
	-activeforeground => 'blue',
	-command=> sub { $config::hash{uc_all}{value} = 0 if $config::hash{lc_all}{value}; }
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>'nw'
);

my $i_chk = $tab5 -> Checkbutton
(
	-text=>"International",
	-variable=>\$config::hash{intr_char}{value},
	-activeforeground => 'blue'
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>'nw'
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
	-activeforeground => 'blue'
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>'nw'
);
$balloon->attach
(
	$b_chk,
	-msg => "Removes Following Characters from Filename.\n\n\~ \@ \# \% \( \) \{ \} \[ \] \" \< \> \! \` \' \,"
);

my $d_chk = $tab5 -> Checkbutton
(
	-text=>"RM ^Digits",
	-variable=>\$config::hash{digits}{value},
	-activeforeground => 'blue',
	-command=> sub
	{
		if($config::hash{digits}{value} == 1)
		{
			$config::hash{RM_DIGITS}{value} = 0;
		}
	}
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>'nw'
);
$balloon->attach
(
	$d_chk,
	-msg => "Removes any digits from begining of filename"
);

my $N_chk = $tab5 -> Checkbutton
(
	-text=>"RM all Digits",
	-variable=>\$config::hash{RM_DIGITS}{value},
	-activeforeground => 'blue',
	-command=> sub
	{
		if($config::hash{RM_DIGITS}{value} == 1)
		{
			$config::hash{digits}{value} = 0;
		}
	}
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>'nw'
);

my $tab5_label_scene = $tab5 -> Label
(
	-justify=>"left",
	-text=>"\nScene Options:\n"
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>'nw'
);

my $unscene_chk = $tab5 -> Checkbutton
(
	-text=>"un-Scenify",
	-variable=>\$config::hash{unscene}{value},
	-activeforeground => 'blue',
	-command=> sub
	{
		if($config::hash{unscene}{value} == 1)
		{
			$config::hash{scene}{value} = 0;
		}
	}
)
-> grid(-row=>$row++, -column=>1, -sticky=>'nw');

$balloon->attach
(
	$unscene_chk,
	-msg => "Converts Season and Episode numbers from scene format to normal format.\n\neg: s10e19 to 10x19"
);

my $scene_chk = $tab5 -> Checkbutton
(
	-text=>"Scenify",
	-variable=>\$config::hash{scene}{value},
	 -activeforeground => 'blue',
	 -command=> sub
	 {
	 	if($config::hash{scene}{value} == 1)
	 	{
	 		$config::hash{unscene}{value} = 0;
	 	}
	 }
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>'nw'
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
	-row=>$row++,
	-column=>1,
	-sticky=>'nw'
);

my $pad_N_to_NN = $tab5 -> Checkbutton
(
	-text=>"Pad N to NN",
	-variable=>\$config::hash{pad_N_to_NN}{value},
	-activeforeground => 'blue'
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>'nw'
);
$balloon->attach
(
	$pad_N_to_NN,
	-msg => "Artist - 1 - track.ogg\nto\nArtist - 01 - track.ogg"
);

my $pad_chk = $tab5 -> Checkbutton
(
	-text=>"Pad - w space",
	-variable=>\$config::hash{pad_dash}{value},
	-activeforeground => 'blue'
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>'nw'
);
$balloon->attach
(
	$pad_chk,
	-msg => "Pads - with user set space delimiter\n\neg: Weird Al-Eat It.mp3 to Weird Al - Eat It.mp3"
);

my $pad_d_chk = $tab5 -> Checkbutton
(
	-text=>"Pad NN w -",
	-variable=>\$config::hash{pad_digits}{value},
	-activeforeground => 'blue'
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>'nw'
);
$balloon->attach
(
	$pad_d_chk,
	-msg => "Pads TRACK and SEASONxEPISODE with \" - \"\n\neg: Norther 10 Hollow.mp3 to Norther - 10 - Hollow.mp3"
);

my $pad_d_w_chk = $tab5 -> Checkbutton
(
	-text=>"Pad NxNN w 0",
	-variable=>\$config::hash{pad_digits_w_zero}{value},
	-activeforeground => 'blue'
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>'nw'
);
$balloon->attach
(
	$pad_d_w_chk,
	-msg => "Pads SEASONxEPISODE with 0.\n\neg: 1x1, 01x1, 1x01 to 01x01."
);

my $chk_split_dddd = $tab5 -> Checkbutton
(
	-text=>"Pad NNNN with x",
	-variable=>\$config::hash{SPLIT_DDDD}{value},
	-activeforeground => 'blue'
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>'nw'
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
	-row=>$row++,
	-column=>1
);

#--------------------------------------------------------------------------------------------------------------
# Enumerate Tab
#--------------------------------------------------------------------------------------------------------------

$row = 1;

$tab6 -> Label
(
	-text=>"Enumerate Options:\n",
	-font => 'Arial 10 bold',
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-columnspan=>2,
	-sticky=>'nw'
);

my $n_chk = $tab6 -> Checkbutton
(
	-text=>"Enumerate",
	-variable=>\$config::hash{enum}{value},
	-activeforeground => 'blue'
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-columnspan=>2,
	-sticky=>'nw'
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
	-row=>$row++,
	-column=>1,
	-columnspan=>2,
	-sticky=>'nw'
);

my $rdb_a = $tab6 -> Radiobutton
(
	-text=>"Numbers only",
	-value=>0,
	-variable=>\$config::hash{enum_opt}{value},
	-activeforeground => 'blue'
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-columnspan=>2,
	-sticky=>'nw'
);
my $rdb_b = $tab6 -> Radiobutton
(
	-text=>"Insert at Start",
	-value=>1,
	-variable=>\$config::hash{enum_opt}{value},
	-activeforeground => 'blue'
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-columnspan=>2,
	-sticky=>'nw'
);
my $rdb_c = $tab6 -> Radiobutton
(
	-text=>"Insert at End",
	-value=>2,
	-variable=>\$config::hash{enum_opt}{value},
	-activeforeground => 'blue'
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-columnspan=>2,
	-sticky=>'nw'
);

$tab6 -> Label
(
	-text=>" "
)
->grid
(
	-row=>$row++,
	-column=>1
);

my $enum_add_checkbox = $tab6 -> Checkbutton
(
	-text=>"Add Strings",
	-variable=>\$config::hash{enum_add}{value},
	-activeforeground => 'blue'
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-columnspan=>2,
	-sticky=>'nw'
);
$balloon->attach
(
	$enum_add_checkbox,
	-msg => "Pad enumerated digits with string.\neg:\nhello.jpg\nto\n01-holidays-hello.jpg"
);


$tab6 -> Label
(
	-text=>"Start String:"
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-columnspan=>2,
	-sticky=>'nw'
);
my $entry_enum_start_str = $tab6 -> Entry
(
	-textvariable=>\$config::enum_start_str
)
-> grid(
	-row=>$row++,
	-column=>1,
	-columnspan=>2,
	-sticky=>'nw'
);

$tab6 -> Label(-text=>'End String:')
-> grid
(
	-row=>$row++,
	-column=>1,
	-columnspan=>2,
	-sticky=>'nw'
);
my $entry_enum_end_str = $tab6 -> Entry
(
	-textvariable=>\$config::enum_end_str
)
-> grid(
	-row=>$row++,
	-column=>1,
	-columnspan=>2,
	-sticky=>'nw'
);
$tab6 -> Label
(
	-text=>" "
)
->grid
(
	-row=>$row++,
	-column=>1
);

$tab6 -> Label
(
	-justify=>"left",
	-text=>"Padding:"
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-columnspan=>2,
	-sticky=>'nw'
);

my $enum_pad_chk = $tab6 -> Checkbutton
(
	-text=>"Pad with zeros",
	-variable=>\$config::hash{enum_pad}{value},
	-activeforeground => 'blue'
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-columnspan=>2,
	-sticky=>'nw'
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
	-row=>$row,
	-column=>1,
	-sticky=>'ne'
);

$tab6 -> Label
(
	-justify=>"left",
	-text=>"zeros"
)
-> grid
(
	-row=>$row++,
	-column=>2,
	-sticky=>'nw'
);

$tab6 -> Label
(
	-text=>"\n\n\n\n\n\n\n\n\n\n\n"
)
->grid
(
	-row=>$row++,
	-column=>1
);

#--------------------------------------------------------------------------------------------------------------
# Truncate
#--------------------------------------------------------------------------------------------------------------

$row = 1;

$tab7 -> Label
(
	-text=>"Truncate Options:\n",
	-font => 'Arial 10 bold',
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-columnspan=>1,
	-sticky=>'nw'
);

my $trunc_chk = $tab7 -> Checkbutton
(
	-text=>"Truncate",
	-variable=>\$config::hash{truncate}{value},
	-activeforeground => 'blue'
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-columnspan=>1,
	-sticky=>'nw'
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
	-row=>$row++,
	-column=>1,
	-sticky=>'nw'
);

my $tfl_ent = $tab7 -> Entry
(
	-textvariable=>\$config::hash{'truncate_to'}{'value'},
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>'nw'
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
	-row=>$row++,
	-column=>1,
	-sticky=>'nw'
);

my $rdb_ts_a = $tab7 -> Radiobutton
(
	-text=>"From Start",
	-value=>"0",
	-variable=>\$config::hash{truncate_style}{value},
	-activeforeground => 'blue'
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>'nw'
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
	-activeforeground => 'blue'
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>'nw'
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
	-activeforeground => 'blue'
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-sticky=>'nw'
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
	-row=>$row++,
	-column=>1,
	-sticky=>'nw'
);

$tab7 -> Label
(
	-justify=>"left",
	-text=>"Insert Character\/s: "
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-columnspan=>1,
	-sticky=>'nw'
);

my $tab7_trunc_ent = $tab7 -> Entry
(
	-textvariable=>\$config::hash{trunc_char}{value},
)
-> grid
(
	-row=>$row++,
	-column=>1,
	-columnspan=>1,
	-sticky=>'nw'
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
	-row=>$row++,
	-column=>1
);


#--------------------------------------------------------------------------------------------------------------
# draw filter 'main screen menu'
#--------------------------------------------------------------------------------------------------------------

our $f_frame = $main::frm_right2->Frame() -> pack(-side=>"top",);

$f_frame -> Checkbutton
(
	-text=>'Filter',
	-variable=>\$config::hash{FILTER}{value},
	-activeforeground => 'blue',
        -command=> sub
	{
		if($config::hash{FILTER}{value} && $config::filter_string eq '')	# don't enable filter on an empty string
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
        -textvariable=>\$config::filter_string,
        -width=>50
)
->pack(-side=>'left',);

$f_frame -> Checkbutton
(
	-text=>"Case In-Sensitive",
	-variable=>\$config::hash{FILTER_IGNORE_CASE}{value},
	-activeforeground => 'blue'
)
->pack(	-side=>'left',);

$f_frame -> Checkbutton
(
	-text=>"regex",
	-variable=>\$config::hash{FILTER_REGEX}{value},
	-activeforeground => 'blue'
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
&dir::ls_dir;

# &style::display;

&misc::plog(1, "Perl version: $^V");
&misc::plog(1, "Tk version: $Tk::VERSION");
&misc::plog(1, "namefix version: $config::version");
&misc::plog(1, "Running on $^O");

# $log_file
&misc::plog(1, "Log file: $main::log_file");

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
