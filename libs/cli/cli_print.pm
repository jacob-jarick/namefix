package cli_print;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;

my $separator = "
<TR>
	<TD colspan=4 align=center bgcolor=\"grey\">***********</TD>
</TR>
";
my $debug_td_open = 0;

my $debug_header = 
"
<!-- debug header -->
<TR>
	<TD colspan=4 align=center><PRE>
";

my $debug_footer = 
"
<!-- debug footer -->
</PRE></TD>
</TR>";

#--------------------------------------------------------------------------------------------------------------
# cli print
#--------------------------------------------------------------------------------------------------------------

# TODO: this module is only referenced in a single file once.
# This was used to output rename information to console and HTML for viewing with a console (or GUI) web browser.
# test and complete, its still a neat feature to have.
# test example: perl .\namefix-cli.pl --uc --recr --html --browser="C:/Program Files/Mozilla Firefox/firefox.exe" C:/git/namefix/temp

sub print
{
	# short circuit if not in cli mode
	if($globals::CLI == 0)
	{
		return;
	}

	my $s1		= shift;	# old filename
	my $s2		= shift;	# new filename, if eq "<MSG>" then s1 is a message to print and $ref1 and $ref2 are ignored / used in alternate ways
	my $ref1	= shift;	# old mp3 id3 tags hash ref
	my $ref2	= shift;	# new mp3 id3 tags hash ref
	my $mode	= shift || 'normal'; # type of print, default is normal

	$mode = lc($mode);
	# proposed modes: list, rename
	# existing modes: message, debug, line

	my %tag_h = ();
	my %tag_h_new = ();

	# define tag hashes for normal + id3 mode
	if($config::hash{id3_mode}{value} && defined $ref1 && defined $ref2)
	{
		%tag_h = %$ref1;
		%tag_h_new = %$ref2;
	}

	{
		my $str1 = 'undefined';
		my $str2 = 'undefined';

		if(defined $s1)
		{
			$str1 = "'$s1'";
		}
		if(defined $s2)
		{
			$str2 = "'$s2'";
		}

		&misc::plog(5, "cli_print::print $str1, $str2");
	}

	if($mode eq "message")
	{
		&debug_close_td;

		for my $line(split(/\n/, $s1))
		{
			print "*** $line\n";
		}

		&html_print("<TR><TD colspan=4>$s1</TD></TR>");
		return 1;
	}

	if($mode eq "debug")
	{
		&debug_open_td;
		print "DEBUG: $s1\n";
		&html_print("<PRE>$s1\n");
		return 1;
	}

	# normal listing

	# normal mode without id3
	if(!$config::hash{id3_mode}{value})
	{
		&debug_close_td;
		print "old> $s1\nnew> $s2\n\n";
		&html_print("<TR><TD  colspan=2 nowrap>$s1</TD><TD  colspan=2 nowrap>$s2</TD></TR>");
		return 1;
	}

	my @mp3_headers = ('Artist', 'Title', 'Track', 'Album', 'Comment', 'Genre', 'Year');

	my $IS_AUDIO_FILE = 0;

	if($s1 =~ /\.($globals::id3_ext_regex)$/i)
	{
		$IS_AUDIO_FILE = 1;
	}

	# loop through mp3 headers and check that all are defined
	for my $h(@mp3_headers)
	{
		my $lc_h = lc($h);

		if(!$IS_AUDIO_FILE)
		{
			$tag_h{$lc_h}		= 'N/A';
			$tag_h_new{$lc_h}	= 'N/A';
			next;
		}

		$tag_h{$lc_h}		= 'undefined' if !defined $tag_h{$lc_h};
		$tag_h_new{$lc_h}	= 'undefined' if !defined $tag_h_new{$lc_h};
	}


	print 	"old>\"$s1\"\nnew>\"$s2\"\n";

	if($IS_AUDIO_FILE)
	{
		for my $h(@mp3_headers)
		{
			my $lc_h = lc($h);
			print 	"\told-$h>	$tag_h{$lc_h}\n".
					"\tnew-$h>	$tag_h_new{$lc_h}\n";
		}
	}
	
my $tmp="
<TR>
	<TD colspan=2 nowrap>$s1</TD>
	<TD colspan=2 nowrap>$s2</TD>
</TR>
";

	if($IS_AUDIO_FILE)
	{
		# loop through mp3 headers and print
		for my $h(@mp3_headers)
		{
			my $lc_h = lc($h);
			$tmp .= 
				"<TR>\n" .
				"\t<TD>$h</TD><TD>$tag_h{$lc_h}</TD>\n" .
				"\t<TD colspan=2>$tag_h_new{$lc_h}</TD>\n" .
				"</TR>\n";
		}
	}

	$tmp .= $separator;

	&debug_close_td;
	&html_print($tmp);

	return;
}

sub html_print
{
	# short circuit if not in cli mode
	if($globals::CLI == 0 || !$config::hash{html_hack}{value})
	{
		return;
	}

	my $s = shift;	# string to print to html

	&misc::file_append($main::html_file, $s);

	return;
}

sub debug_open_td
{
	if(! $debug_td_open)
	{
		&html_print($debug_header);
		$debug_td_open = 1;
	}
	return;
}

sub debug_close_td
{
	if($debug_td_open)
	{
		&html_print($debug_footer);
		$debug_td_open = 0;
	}
	return;
}

sub page_header
{
	# short circuit if not in cli mode
	if($globals::CLI == 0 || !$config::hash{html_hack}{value})
	{
		return;
	}

	my $title = shift || 'NameFix CLI Output';

	my $header = <<'END_HEADER';
<!DOCTYPE html>
<table border=1>
<TR>
	<TD colspan=2>
		<b>Before</b>
	</TD>
	<TD colspan=2>
		<b>After</b>
	</TD>
</TR>

END_HEADER

	&html_print($header);
	return;
}

1;
