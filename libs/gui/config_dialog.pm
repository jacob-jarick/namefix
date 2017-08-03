package config_dialog;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;

#--------------------------------------------------------------------------------------------------------------
# Edit Preferences
#--------------------------------------------------------------------------------------------------------------

sub edit_prefs
{
	$main::load_defaults = 0;
	my $n = 0;

        my $top = $main::mw -> Toplevel
	(
        	-padx => 5,
        	-pady => 5
        );

        $top -> title("Edit Preferences");

        my $book = $top->NoteBook()
        -> grid
	(
        	-row=>1,
        	-column=>1,
        	-columnspan=>2,
        	-sticky=>'nw'
        );

	# ----------------------------------------------------------------------------------------------------------
	# Main prefences tab

        my $tab1 = $book->add
	(
        	"Sheet 1",
        	-label=>"Main"
        );

        my $tab1_label_mo = $tab1 -> Label
	(
        	-justify=>"left",
        	-text=>"Main system options for namefix.pl:\n"
        )
	-> grid
	(
		-row=>1,
		-column=>1,
		-sticky=>"nw"
	);

	$tab1 -> Label
	(
		-text=>" "
	)
	-> grid
	(
		-row=>4,
		-column=>1,
		-sticky=>"nw"
	);

	my $label6 = $tab1 -> Label
	(
		-justify=>"left",
		-text=>"Space Delimter: "
	)
	-> grid
	(
		-row=>5,
		-column=>1,
		-sticky=>"nw"
	);

	my $e_ent = $tab1 -> Entry
	(
		-textvariable=>\$main::space_character,
		-width=>5
	)
	-> grid
	(
		-row=>5,
		-column=>2,
		-sticky=>"nw"
	);
	$main::balloon->attach
	(
		$e_ent,
		-msg => "Enter your \ prefered space delimiter.\n\nPopular choices are: \"_\" \".\" \" \" "
	);

	$tab1 -> Label
	(
		-text=>" "
	)
	-> grid
	(
		-row=>7,
		-column=>1,
		-sticky=>"nw"
	);

	$tab1 -> Label
	(
		-justify=>"left",
		-text=>"Maximum Filename Length: "
	)
	-> grid
	(
		-row=>8,
		-column=>1,
		-sticky=>"nw"
	);

	my $mfnl_ent = $tab1 -> Entry
	(
		-textvariable=>\$main::max_fn_length,
		-width=>5
        )
	-> grid
	(
		-row=>8,
		-column=>2,
		-sticky=>"nw"
	);
	$main::balloon->attach
	(
		$mfnl_ent,
		-msg => "Files will not be renamed if new name exceeds max length"
	);

	$tab1 -> Label
	(
		-justify=>"left",
		-text=>" "
	)
	-> grid
	(
		-row=>9,
		-column=>1,
		-sticky=>"nw"
	);

	$tab1 -> Label
	(
		-text=>" "
	)
	-> grid
	(
		-row=>13,
		-column=>1,
		-sticky=>"nw"
	);

	my $save_window_size_chk = $tab1 -> Checkbutton
	(
		-text=>"Save main window size and position",
		-variable=>\$main::SAVE_WINDOW_SIZE,
		-activeforeground => "blue"
	)
	-> grid
	(
		-row=>14,
		-column=>1,
		-columnspan=>2,
		-sticky=>"sw"
	);

	my $save_defs_chk = $tab1 -> Checkbutton
	(
		-text=>"Save main window options",
		-variable=>\$main::load_defaults,
		-activeforeground => "blue"
	)
	-> grid
	(
		-row=>15,
		-column=>1,
		-columnspan=>2,
		-sticky=>"sw"
	);
	$main::balloon->attach
	(
		$save_defs_chk,
		-msg => "Saves safe options from main window as defaults.\nUnsafe options can be set by manually editing the\nconfig file.\n\nOptions Deemed Safe:\n\n\tCleanup\n\tCasing\n\tSpecific Casing\n\tSpaces\n\t. to Space\n\tRM Word List\n\tRM Pattern List\n\n\tid3 mode\n\n\tUppercase All\n\tLowercase All\n\tInternational.\n\n\tEnumerate Styles\n\tTruncate Styles"
	);

	$tab1 -> Label
	(
		-text=>"\n"
	)
	-> grid
	(
		-row=>20,
		-column=>1,
		-sticky=>"nw"
	);

	# ----------------------------------------------------------------------------------------------------------
	# Advanced options tab

	my $tab7 = $book->add
	(
		"Sheet 2",
		-label=>"Advanced"
	);

	$tab7 -> Label
	(
		-justify=>"left",
		-text=>"Advance system options for namefix.pl:\n"
	)
	-> grid(
		-row=>1,
		-column=>1,
		-sticky=>"nw"
	);

	my $F_chk = $tab7 -> Checkbutton
	(
		-text=>"FS Fix (Case insensitive file system workaround)",
		-variable=>\$main::fat32fix,
		-activeforeground => "blue"
	)
	-> grid
	(
		-row=>2,
		-column=>1,
		-sticky=>"nw",
		-columnspan=>2
	);
	$main::balloon->attach
	(
		$F_chk,
		-msg => "Enabled by default for win32 OS's\nFile systems known to have this issue: NTFS, Fat32, HFS.\n\neg: renaming test.mp3 to Test.mp3 will fail if FS is case insensitive."
	);

	my $tab7_regexp_chk = $tab7 -> Checkbutton
	(
		-text=>"Disable Regexp pattern matching for Remove option",
		-variable=>\$main::disable_regexp,
		-activeforeground => "blue"
	)
	-> grid
	(
		-row=>3,
		-column=>1,
		-sticky=>"nw",
		-columnspan=>2
	);
	$main::balloon->attach
	(
		$tab7_regexp_chk,
		-msg => "Disabled by default for novice users"
	);

	$tab7 -> Label
	(
		-text=>" "
	)
	-> grid
	(
		-row=>4,
		-column=>1,
		-sticky=>"nw"
	);

	$tab7 -> Label
	(
		-justify=>"left",
		-text=>"Media File Extensions: "
	)
	-> grid
	(
		-row=>11,
		-column=>1,
		-sticky=>"nw"
	);

	my $mfe_ent = $tab7 -> Entry
	(
		-textvariable=>\$main::file_ext_2_proc,
		-width=>60
	)
	-> grid
	(
		-row=>12,
		-column=>1,
		-columnspan=>2,
		-sticky=>"nw"
	);
	$main::balloon->attach
	(
		$mfe_ent,
		-msg => "Enter File extensions of files you wish seperated by |.\nThey will be processed by default.\n\nNote: Case insensitive matching is used."
	);

	$tab7 -> Label
	(
		-text=>"\n"
	)
	-> grid
	(
		-row=>20,
		-column=>1,
		-sticky=>"nw"
	);

	my $overwrite_chk = $tab7 -> Checkbutton
	(
		-text=>"Overwrite",
		-variable=>\$main::overwrite,
		-activeforeground => "blue"
	)
	-> grid
	(
		-row=>23,
		-column=>1,
		-sticky=>"nw",
	);

	$main::balloon->attach
	(
		$overwrite_chk,
		-msg => "Overwrite: Preform rename without checking if new filename exists.\n\nThis Option is not saved, Please be carefull witht this option"
	);

	# ----------------------------------------------------------------------------------------------------------
	# Debug tab

	$n = 1;

	my $tab_debug = $book->add
	(
		"Sheet 3",
		-label=>"Debug"
	);

	$tab_debug -> Label
	(
		-justify=>"left",
		-text=>"Debug Level"
	)
	-> grid
	(
		-row=>$n,
		-column=>1,
		-sticky=>"nw"
	);

	my $spin_pad_enum = $tab_debug -> Spinbox
	(
		-textvariable=>\$main::debug,
		-from=>0,
		-to=>10,
		-increment=>1,
		-width=>2
	)
	-> grid
	(
		-row=>$n++,
		-column=>2,
		-sticky=>"nw",
	);

	$tab_debug -> Checkbutton
	(
		-text=>"Print log to stdout",
		-variable=>\$main::LOG_STDOUT,
		-activeforeground => "blue"
	)
	-> grid
	(
		-row=>$n++,
		-column=>1,
		-sticky=>"nw",
	);

	$tab_debug -> Checkbutton
	(
		-text=>"Print errors to stdout",
		-variable=>\$main::ERROR_STDOUT,
		-activeforeground => "blue"
	)
	-> grid
	(
		-row=>$n++,
		-column=>1,
		-sticky=>"nw",
	);

	$tab_debug -> Checkbutton
	(
		-text=>"Pop up errors in a dialog box",
		-variable=>\$main::ERROR_NOTIFY,
		-activeforeground => "blue"
	)
	-> grid
	(
		-row=>$n++,
		-column=>1,
		-sticky=>"nw",
	);

	$tab_debug -> Checkbutton
	(
		-text=>"Zero logfile on start",
		-variable=>\$main::ZERO_LOG,
		-activeforeground => "blue"
	)
	-> grid
	(
		-row=>$n++,
		-column=>1,
		-sticky=>"nw",
	);

	# ----------------------------------------------------------------------------------------------------------
	# Save n Close Buttons

        my $but_save = $top -> Button(
        	-text=>"Save",
        	-activebackground => 'white',
        	-command => sub {
        		\&config::save();
        	}
        )
        -> grid(
        	-row =>5,
        	-column => 1,
        	-sticky=>"ne"
        );
        my $but_close = $top -> Button(
        	-text=>"Close",
        	-activebackground => 'white',
        	-command => sub {
        		destroy $top;
        	}
        )
        -> grid(
        	-row =>5,
        	-column => 2,
        	-sticky=>"nw"
        );

	$main::balloon->attach(
		$but_save,
		-msg => "Save Preferences to config file."
	);

	$top->resizable(0,0);
}

#--------------------------------------------------------------------------------------------------------------
# Save Fonts Config File
#--------------------------------------------------------------------------------------------------------------

sub save_fonts
{
	open(FILE, ">$main::fonts_file") or die "ERROR: couldnt open $main::fonts_file to write to\n$!\n";

	print FILE

	"# namefix.pl $main::version fonts configuration file\n",
	"# manually edit the fonts below if your sizes are screwed up in the dialog windows\n",
	"\n",
	"\$dialog_font 		= \"$main::dialog_font\"; 		\n",
	"\$dialog_title_font 	= \"$main::dialog_title_font\"; 	\n",
	"\$edit_pat_font	= \"$main::edit_pat_font\"; 		\n",
	"\n";

	close(FILE);
}


1;