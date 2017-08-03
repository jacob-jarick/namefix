package config;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;
use Data::Dumper::Concise;
use FindBin qw($Bin);

our %hash = ();

our $hash_tsv = &misc::get_home."/.namefix.pl/config_hash.tsv";

$hash{'space_character'}{'save'}	= 'norm';
$hash{'space_character'}{'value'}	= ' ';

$hash{'$max_fn_length'}{'save'}		= 'norm';
$hash{'$max_fn_length'}{'value'}	= 256;

$hash{'fat32fix'}{'save'}		= 'norm';
$hash{'fat32fix'}{'value'}		= 0;

$hash{'FILTER_REGEX'}{'save'}		= 'norm';
$hash{'FILTER_REGEX'}{'value'}		= 0;

$hash{'file_ext_2_proc'}{'save'}	= 'norm';
$hash{'file_ext_2_proc'}{'value'}	= "jpeg|jpg|mp3|mpc|mpg|mpeg|avi|asf|wmf|wmv|ogg|ogm|rm|rmvb|mkv";

$hash{'debug'}{'save'}			= 'norm';
$hash{'debug'}{'value'}			= 0;

$hash{'LOG_STDOUT'}{'save'}		= 'norm';
$hash{'LOG_STDOUT'}{'value'}		= 0;

$hash{'ERROR_STDOUT'}{'save'}		= 'norm';
$hash{'ERROR_STDOUT'}{'value'}		= 0;

$hash{'ERROR_NOTIFY'}{'save'}		= 'norm';
$hash{'ERROR_NOTIFY'}{'value'}		= 0;

$hash{'ZERO_LOG'}{'save'}		= 'norm';
$hash{'ZERO_LOG'}{'value'}		= 1;

$hash{'HTML_HACK'}{'save'}		= 'norm';
$hash{'HTML_HACK'}{'value'}		= 0;

$hash{'browser'}{'save'}		= 'norm';
$hash{'browser'}{'value'}		= '';

$hash{'editor'}{'save'}			= 'norm';
$hash{'editor'}{'value'}		= '';

$hash{'case'}{'save'}			= 'mw';
$hash{'case'}{'value'}			= 0;

$hash{'WORD_SPECIAL_CASING'}{'save'}	= 'mw';
$hash{'WORD_SPECIAL_CASING'}{'value'}	= 0;

$hash{'spaces'}{'save'}			= 'mw';
$hash{'spaces'}{'value'}		= 0;

$hash{'dot2space'}{'save'}		= 'mw';
$hash{'dot2space'}{'value'}		= 0;

$hash{'kill_cwords'}{'save'}		= 'mw';
$hash{'kill_cwords'}{'value'}		= 0;

$hash{'kill_sp_patterns'}{'save'}	= 'mw';
$hash{'kill_sp_patterns'}{'value'}	= 0;

$hash{'sp_char'}{'save'}		= 'mw';
$hash{'sp_char'}{'value'}		= 0;

$hash{'intr_char'}{'save'}		= 'mw';
$hash{'intr_char'}{'value'}		= 0;

$hash{'lc_all'}{'save'}			= 'mw';
$hash{'lc_all'}{'value'}		= 0;

$hash{'uc_all'}{'save'}			= 'mw';
$hash{'uc_all'}{'value'}		= 0;

$hash{'id3_mode'}{'save'}		= 'mw';
$hash{'id3_mode'}{'value'}		= 0;

$hash{'id3_guess_tag'}{'save'}		= 'mw';
$hash{'id3_guess_tag'}{'value'}		= 0;

$hash{'enum_opt'}{'save'}		= 'mw';
$hash{'enum_opt'}{'value'}		= 0;

$hash{'enum_pad'}{'save'}		= 'mw';
$hash{'enum_pad'}{'value'}		= 0;

$hash{'enum_pad_zeros'}{'save'}		= 'mw';
$hash{'enum_pad_zeros'}{'value'}	= 0;

$hash{'truncate'}{'save'}		= 'mw';
$hash{'truncate'}{'value'}		= 0;

$hash{'truncate_style'}{'save'}		= 'mw';
$hash{'truncate_style'}{'value'}	= 0;

$hash{'trunc_char'}{'save'}		= 'mw';
$hash{'trunc_char'}{'value'}		= 0;

$hash{'truncate_to'}{'save'}		= 'mw';
$hash{'truncate_to'}{'value'}		= 0;

$hash{'save_window_size'}{'save'}	= 'mwg';
$hash{'save_window_size'}{'value'}	= 0;

$hash{'window_g'}{'save'}		= 'mwg';
$hash{'window_g'}{'value'}		= '';


sub save_hash
{
	&misc::plog(0, "config::save_hash $hash_tsv");
	&misc::null_file($hash_tsv);
	for my $k(keys %hash)
	{
		if(!defined $hash{$k}{'value'})
		{
			&misc::plog(0, "config::save_hash key $k has no value");
			print "$k = \n" . Dumper($hash{$k});
			next;
		}
		&misc::file_append($hash_tsv, "$k\t".$hash{$k}{'value'}."\n");
	}
}


sub load_hash
{
	&misc::plog(0, "config::save_hash $hash_tsv");
	my @tmp = &misc::readf($hash_tsv);
	my %h = ();
	for my $line(@tmp)
	{
		my ($k, $v) = split(/\t/, $line);
		$h{$k}{value} = $v;
	}
	for my $k(keys %hash)
	{
		if(!defined $h{$k}{'value'})
		{
			&misc::plog(0, "config::load_hash key $k has no value");
			print "$k = \n" . Dumper($hash{$k});
			next;
		}
		$hash{$k}{value} = $h{$k}{value};
	}
}

#--------------------------------------------------------------------------------------------------------------
# Save Config File
#--------------------------------------------------------------------------------------------------------------

# MEMO: to self, config file is for stuff under prefs dialog only and defaults is for mainwindow vars
sub save
{
	&save_hash;
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