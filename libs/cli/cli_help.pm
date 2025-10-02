# namefix cli help
package cli_help;
require Exporter;
@ISA = qw(Exporter);

use warnings;
use strict;

sub show
{

	my $mode = shift;
	if(!$mode) { $mode = "long"; }

	my $txt_header="namefix.pl $config::version

namefix-cli.pl -<shortoptions> <target>
namefix-cli.pl --<longoption1> --<longoption2> --<longoption3=value> <target>
namefix-cli.pl -<shortoptions> --<longoption1> --<longoption2=value> <target>
";

my $txt_help =
"h	--help			help list
	--help-short		Short Help (Most used options)
	--help-long		Long Help (Short, Advanced & Misc options)
	--help-misc		Misc options
	--help-adv		Advance options
	--help-mp3		Mp3 options
	--help-trunc		Truncate options
	--help-enum		Enumerate options
	--help-doc		Document and Config options
	--help-debug		Debug Options
	--help-hacks		Hack options
	--help-all		All help (Long list of options)

";

my $txt_main = "Main Options:

!	--rename		perform rename
	--ren			enable once you are happy with preview.
				Without this option namefix defaults to
				preview mode.

	--undo			undo last rename

g	--clean			general cleanup (recommend)

c	--case			Fix case
p	--spaces		Convert _ and \" \" to set space delimiter
				current space delimiter: \"$config::hash{space_character}{value}\"
o	--dots			Dots \".\" to Space Delimiter
x	--regexp		Enable regexp in --remove option

	--remove=STRING		Remove STRING from filename
	--rm=STRING

	--replace=STRING	Replace removed string with STRING
	--rp=STRING		This option will be disabled
				if remove is not invoked

	--append-front=STRING	Append STRING to the start of filename
	--af=STRING

	--append-end=STRING	Append STRING to the end of filename
	--ae=STRING

C	--case-sp		Use special Casing list:
				$config::casing_file

K	--rm-words		Remove Custom Words list
				$config::killwords_file

P	--rm-pat		Remove Custom regexp patterns, ie urls
				$config::killpat_file

F	--fs-fix		Work around case insensitive filesystems
				eg microsofts fat32

";
my $txt_trunc = "Truncate Options:

	--trunc=N		truncate filenames to N length
	--trunc-pat=N		Select truncate pattern
				0 = Truncate from Start (Default)
				1 = Truncate from Middle
				2 = Truncate from End

	--trunc-ins=STRING	When using --trunc-pat=1
				Insert STRING in middle of filename

";
my $txt_enum =
"Enumerate Options:

	--enum			enumerate filenames
	--enum-style=N		Select enumeration method
				0 = Numbers Only (removes filename)
				1 = Insert at start of filename (Default)
				2 = Insert at end of filename.

	--enum-zero-pad=N	N = Pad enum number to N zeros

";
my $txt_misc =
"Misc Options:

i	--int			convert international characters to
				english equivalent

7	--7bit			convert all characters to 7bit ascii

s	--scene			Scenify Season and Episode Numbers
	--sc

u	--unscene		Unscenify Season and Episode Numbers
	--usc

U	--uc			uppercase all letters of filename
L	--lc			lowercase all letters of filename

	--rm-nc			remove nasty characters
	--rmc

	--rm-starting-digits	remove all digits from start of filename
	--rsd

	--rm-all-digits		remove all digits from filename
	--rad			Excluding file extension

H	--pad-hyphen		pad / hyphen dashes with space delimiter \"$config::hash{space_character}{value}\"
	--ph

N	--pad-num		pad digits with -
	--pn			Aimed at track & EpisodexSeason numbers
				eg: \"Artist 10 Title.mp3\" to
				\"Artist - 10 - Title.mp3\"

0	--pad-num-w0		Pad numbers with zero's
	--p0			eg: track & EpisodexSeason numbers
				2x12 to 02x12, 3x4 to 03x05 etc

	--pad-nnnn-wx		Pad SeasonEpisode numbers with x
	--px			before: Show 0104 Episode title.avi
				after : Show 01x04 Episode title.avi

	--gui-test		Test GUI startup (for debugging only)
				Starts the GUI and exits

";
my $txt_advance =
"Advanced Options:

	--save-options		Save current options as default
	--save-opt		config file is located at:
	--save-config		$config::hash_tsv

	--recr			Recursive mode
				Warning: Use with caution

D	--dir			process directories
				Warning: Use with caution

	--overwrite		Perform rename without checking if new filename exists.
				Please be careful with this option

A	--all-files		Process all files, not just media files.

	--filt=STRING		Filter files processed. must contain STRING
	--filt-regexp		filter STRING is a regexp

	--space-char=C		C = Space Delimiter character
	--spc=C			Override default space delimiter \"$config::hash{space_character}{value}\"
				and use C

	--media-types=STRING	only process the file extensions listed in STRING
	--mt=STRING		STRING format: \"<file_ext1>|<file_ext2>\"
				Default file types processed:
				$config::hash{file_ext_2_proc}{value}

";
my $txt_hacks =
"Hacks:

	--html			output is formatted as html
				Then viewed in a console mode browser:
				$config::hash{browser}{value}

	--browser		set browser to use for html hack

";
my $txt_docs =
"Documentation Options

	--help

	--changelog		prints out entire changelog
	--about			prints about info
	--todo			prints namefix.pl's todo list
	--thanks		Credit / Thankyou list of contributors.
	--links			Recommend Links from the author

	--editor=STRING		Set editor to STRING

	--ed-config		Edit namefix.pl's config
	--ed-spcase		Edit Special Casing List
	--ed-rmwords		Edit Remove Word List
	--ed-rmpat		Edit Remove Regexp Patterns List

	--show-log		Dumps namefix.pl's log file to STDOUT

";
my $txt_debug =
"Debug Options:

	--debug=N		Set debug level to N (0-10)
	--debug-stdout		Print debug log to stdout

";
my $txt_mp3 =
"MP3 Options

	--id3-guess		guess mp3 tags from filename
	--id3-overwrite		overwrite existing id3 tags
	--id3-rm-v1		remove v1 id3 tags
	--id3-rm-v2		remove v2 id3 tags
	--id3-art=STRING	Set id3 artist tag to STRING
	--id3-tit=STRING	Set id3 title tag to STRING
	--id3-tra=STRING	Set id3 track tag to STRING
	--id3-alb=STRING	Set id3 album tag to STRING
	--id3-yer=STRING	Set id3 year tag to STRING
	--id3-com=STRING	Set id3 comment tag to STRING

";

my $text_exif =
"
EXIF Data Options:

	--exif-show		Show all available EXIF data
	--exif-rm		Remove all EXIF data (WIP)


";

	my $msg_help=
	$txt_header.
	$txt_help;

	my $txt_short=
	$txt_header.
	$txt_main;

	my $msg_long =
	$txt_short.
	$txt_misc.
	$txt_advance;

	my $msg_all =
	$txt_short.
	$txt_trunc.
	$txt_enum.
	$txt_misc.
	$txt_advance.
	$txt_hacks.
	$txt_docs.
	$txt_debug.
	$txt_mp3.
	$text_exif;

	if($mode eq "help")
	{
		print $msg_help;
	}
	elsif($mode eq "short")
	{
		print $txt_short;
	}
	elsif($mode eq "long")
	{
		print $msg_long;
	}
	elsif($mode eq "misc")
	{
		print $txt_misc;
	}
	elsif($mode eq "adv")
	{
		print $txt_advance;
	}
	elsif($mode eq "all")
	{
		print $msg_all;
	}
	elsif($mode eq "trunc")
	{
		print $txt_trunc;
	}
	elsif($mode eq "enum")
	{
		print $txt_enum;
	}
	elsif($mode eq "mp3")
	{
		print $txt_mp3;
	}
	elsif($mode eq "doc")
	{
		print $txt_docs;
	}
	elsif($mode eq "debug")
	{
		print $txt_debug;
	}
	elsif($mode eq "hacks")
	{
		print $txt_hacks;
	}
	elsif($mode eq "exif")
	{
		print $text_exif;
	}

	else
	{
		&misc::plog(0, "sub cli_help: help called, but mode \"$mode\" is invalid");
	}

	exit 1;
};



1;
