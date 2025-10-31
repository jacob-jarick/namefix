package cli_print;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;

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

	if(!$s2) { $s2 = $s1; }

	my %tag_h = ();
	my %tag_h_new = ();

	if($config::hash{id3_mode}{value} && defined $ref1 && defined $ref2)
	{
		%tag_h = %$ref1;
		%tag_h_new = %$ref2;
	}

	my $tmp = '';

	&misc::plog(3, "sub cli_print: \"$s1\", \"$s2\"");

	if($s2 eq "<MSG>")
	{
		for my $line(split(/\n/, $s1))
		{
			print "*** $line\n";
		}

		&htmlh::html("<TR><TD colspan=4>$s1</TD></TR>");
		return 1;
	}

	# normal listing

	if(!$config::hash{id3_mode}{value})
	{
		print "old> $s1\nnew> $s2\n\n";
		&htmlh::html("<TR><TD  colspan=2 nowrap>$s1</TD><TD  colspan=2 nowrap>$s2</TD></TR>");
		return 1;
	}
	else
	{
		print 	"old>\"$s1\"\nnew>\"$s2\"\n",
			"\told-artist>	$tag_h{artist}\n\tnew-artist>	$tag_h_new{artist}\n",
			"\told-title>	$tag_h{title}\n\tnew-title>	$tag_h_new{title}\n",
			"\told-track>	$tag_h{track}\n\tnew-track>	$tag_h_new{track}\n",
			"\told-album>	$tag_h{album}\n\tnew-album>	$tag_h_new{album}\n",
			"\told-comment>	$tag_h{comment}\n\tnew-comment>	$tag_h_new{comment}\n",
			"\told-genre>	$tag_h{genre}\n\tnew-genre>	$tag_h_new{genre}\n",
			"\told-year>	$tag_h{year}\n\tnew-year>	$tag_h_new{year}\n\n";

$tmp="
<TR>
	<TD colspan=2 nowrap>$s1</TD>
	<TD colspan=2 nowrap>$s2</TD></TR>
<TR>
	<TD>Artist</TD><TD>$tag_h{artist}</TD>
	<TD colspan=2>$tag_h_new{artist}</TD>
</TR>
<TR>
	<TD>Title</TD><TD>$tag_h{title}</TD>
	<TD colspan=2>$tag_h_new{title}</TD>
</TR>
<TR>
	<TD>Track</TD><TD>$tag_h{track}</TD>
	<TD colspan=2>$tag_h_new{track}</TD>
</TR>
<TR>
	<TD>Album</TD><TD>$tag_h{album}</TD>
	<TD colspan=2>$tag_h_new{album}</TD>
</TR>
<TR>
	<TD>Comment</TD><TD>$tag_h{comment}</TD>
	<TD colspan=2>$tag_h_new{comment}</TD>
</TR>
<TR>
	<TD>Genre</TD><TD>$tag_h{genre}</TD>
	<TD colspan=2>$tag_h_new{genre}</TD>
</TR>
<TR>
	<TD>Year</TD><TD>$tag_h{year}</TD>
	<TD colspan=2>$tag_h_new{year}</TD>
</TR>
<TR>
	<TD colspan=4 align=center>***********</TD>
</tr>
";

		&htmlh::html($tmp);

		return 1;
	}
	return;

}

1;
