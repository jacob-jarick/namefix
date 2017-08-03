package config;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;

use FindBin qw($Bin);

#--------------------------------------------------------------------------------------------------------------
# Save Config File
#--------------------------------------------------------------------------------------------------------------

# MEMO: to self, config file is for stuff under prefs dialog only and defaults is for mainwindow vars
sub save
{
	open(FILE, ">$main::config_file");
	print FILE "\# namefix.pl $main::version config file\n",
		   "\# treated as perl script - dont fuck up if doing manual edit.\n\n";

	print FILE

	"\$space_character	= \"$main::space_character\";\n",
	"\$max_fn_length	= $main::max_fn_length;\n",
	"\n",
	"\$fat32fix		= $main::fat32fix;\n",
	"\$FILTER_REGEX 	= $main::FILTER_REGEX;\n",
	"\$file_ext_2_proc	= \"$main::file_ext_2_proc\";\n",
	"\$debug		= $main::debug;\n",
	"\$LOG_STDOUT		= $main::LOG_STDOUT;\n",
	"\$ERROR_STDOUT		= $main::ERROR_STDOUT;\n",
	"\$ERROR_NOTIFY		= $main::ERROR_NOTIFY;\n",
	"\$ZERO_LOG		= $main::ZERO_LOG;\n",
	"\$HTML_HACK		= $main::HTML_HACK;\n",
	"\$browser		= \"$main::browser\";\n",
	"\$editor		= \"$main::editor\";\n",
	"\n",
	 "\n";

	if
	(
		$main::load_defaults == 1 || 	# gui option user selects to save mainwindow options
		$main::CLI			# if running from cli, save options
	) {

		print FILE

		"\n\# main window options\n\n",

		"\$case 		= $main::case;\n",
		"\$WORD_SPECIAL_CASING	= $main::WORD_SPECIAL_CASING;\n",

		"\$spaces		= $main::spaces;\n",
		"\$dot2space		= $main::dot2space;\n",
		"\$kill_cwords		= $main::kill_cwords;\n",
		"\$kill_sp_patterns	= $main::kill_sp_patterns;\n",
		"\$sp_char		= $main::sp_char;\n",
		"\$intr_char		= $main::intr_char;\n",

		"\$lc_all		= $main::lc_all;\n",
		"\$uc_all		= $main::uc_all;\n",

		"\$id3_mode		= $main::id3_mode;\n",
		"\$id3_guess_tag	= $main::id3_guess_tag;\n",

		"\$enum_opt		= $main::enum_opt;\n",
		"\$enum_pad		= $main::enum_pad;\n",
		"\$enum_pad_zeros	= $main::enum_pad_zeros;\n",

		"\$truncate		= $main::truncate;\n",
		"\$truncate_style	= $main::truncate_style;\n",
		"\$trunc_char		= \"$main::trunc_char\";\n",
                "\$truncate_to		= \"$main::truncate_to\";\n",

		"\n";
	}

	if($main::SAVE_WINDOW_SIZE == 1 && !$main::CLI)
	{
		$main::window_g = $main::mw->geometry;

		print FILE

                "\$save_window_size = 1;\n",
		"\$window_g = \"$main::window_g\";\n\n";
	}
	print FILE	   "\# end of config file";
	close(FILE);
}


1;