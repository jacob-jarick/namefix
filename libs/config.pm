package config;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;
use Data::Dumper::Concise;
use FindBin qw($Bin);

# writable_extensions - stolen from mp3::tag and tidied
our @id3v2_exts = ("mp3", "mp2", "ogg", "mpg", "mpeg", "mp4", "aiff", "flac", "ape", "ram", "mpc");

our $id3_ext_regex = join('|', @config::id3v2_exts);

print "\$id3_ext_regex = $id3_ext_regex\n";

our %hash = ();

our $hash_tsv = &misc::get_home."/.namefix.pl/config_hash.tsv";
$hash_tsv =~ s/\\/\//g;

$hash{'space_character'}{'save'}	= 'norm';
$hash{'space_character'}{'value'}	= ' ';

$hash{'max_fn_length'}{'save'}		= 'norm';
$hash{'max_fn_length'}{'value'}		= 256;

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
$hash{'editor'}{'value'}		= 'vim';

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
$hash{'enum_pad_zeros'}{'value'}	= 4;

$hash{'truncate'}{'save'}		= 'mw';
$hash{'truncate'}{'value'}		= 0;

$hash{'truncate_style'}{'save'}		= 'mw';
$hash{'truncate_style'}{'value'}	= 0;

$hash{'trunc_char'}{'save'}		= 'mw';
$hash{'trunc_char'}{'value'}		= 0;

$hash{'truncate_to'}{'save'}		= 'mw';
$hash{'truncate_to'}{'value'}		= 256;

$hash{'save_window_size'}{'save'}	= 'mwg';
$hash{'save_window_size'}{'value'}	= 0;

$hash{'window_g'}{'save'}		= 'mwg';
$hash{'window_g'}{'value'}		= '';


sub save_hash
{
	&misc::plog(0, "config::save_hash $hash_tsv");
	&misc::null_file($hash_tsv);

	my @types = ('norm', 'mw', 'mwg');

	for my $t (@types)
	{
		&misc::file_append($hash_tsv, "\n######## $t ########\n\n");
		for my $k(sort { $a cmp $b } keys %hash)
		{
			next if $hash{$k}{'save'} ne $t;
			save_hash_helper($k);
		}
	}
}

sub save_hash_helper
{
	$config::hash{window_g}{value} = $main::mw->geometry;

	my $k = shift;
	if(!defined $hash{$k}{'value'})
	{
		my $w = "config::save_hash key $k has no value";
		&misc::plog(0, $w);
		print "$w\n$k = \n" . Dumper($hash{$k});
		next;
	}
	&misc::file_append($hash_tsv, "$k\t\t".$hash{$k}{'value'}."\n");
}


sub load_hash
{
	&misc::plog(0, "config::save_hash $hash_tsv");
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
		if(!defined $h{$k}{'value'} && $h{$k}{'value'} ne '')
		{
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
}


1;