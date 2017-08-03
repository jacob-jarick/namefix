package cli_print;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;

#--------------------------------------------------------------------------------------------------------------
# cli print
#--------------------------------------------------------------------------------------------------------------

sub cli_print
{
	my $s1 = shift;
	my $s2 = shift;

	if(!$s2) { $s2 = $s1; }

	my $art = "";
	my $tit = "";
	my $tra = "";
	my $alb = "";
	my $com = "";
	my $gen = "";
	my $year = "";

	my $newart = "";
	my $newtit = "";
	my $newtra = "";
	my $newalb = "";
	my $newcom = "";
	my $newgen = "";
	my $newyear = "";

	my $tmp = "";

	&misc::plog(3, "sub cli_print: \"$s1\", \"$s2\"");

	if($s2 eq "<MSG>")
	{
		for(split(/\n/, $s1))
		{
			print "*** $_\n";
		}
		&htmlh::html("<TR><TD colspan=4>$s1</TD></TR>");
		return 1;
	}

	if($main::id3_mode == 1)
	{
		$art = shift;
		$tit = shift;
		$tra = shift;
		$alb = shift;
		$com = shift;
                $gen = shift;
                $year = shift;
	}

	# When renaming or previewing in id3 mode we will be sent the "after" id3 tags
	if($main::id3_mode == 1 && $main::LISTING == 0)
	{
		$newart = shift;
		$newtit = shift;
		$newtra = shift;
		$newalb = shift;
		$newcom = shift;
		$newgen = shift;
		$newyear = shift;
	}

	# normal listing

	if(!$main::id3_mode)
	{
		print "old> $s1\nnew> $s2\n\n";
		&htmlh::html("<TR><TD  colspan=2 nowrap>$s1</TD><TD  colspan=2 nowrap>$s2</TD></TR>");
		return 1;
	}
	else
	{
		print 	"old>\"$s1\"\nnew>\"$s2\"\n",
			"\told-artist>$art\n\tnew-artist>$newart\n",
			"\told-title>$tit\n\tnew-title>$newtit\n",
			"\told-track>$tra\n\tnew-track>$newtra\n",
			"\told-album>$alb\n\tnew-album>$newalb\n",
			"\told-comment>$com\n\tnew-comment>$newcom\n",
			"\told-genre>$gen\n\tnew-genre>$newgen\n",
			"\told-year>$year\n\tnew-year>$newyear\n\n";

$tmp="
<TR>
	<TD colspan=2 nowrap>$s1</TD>
	<TD colspan=2 nowrap>$s2</TD></TR>
<TR>
	<TD>Artist</TD><TD>$art</TD>
	<TD colspan=2>$newart</TD>
</TR>
<TR>
	<TD>Title</TD><TD>$tit</TD>
	<TD colspan=2>$newtit</TD>
</TR>
<TR>
	<TD>Track</TD><TD>$tra</TD>
	<TD colspan=2>$newtra</TD>
</TR>
<TR>
	<TD>Album</TD><TD>$alb</TD>
	<TD colspan=2>$newalb</TD>
</TR>
<TR>
	<TD>Comment</TD><TD>$com</TD>
	<TD colspan=2>$newcom</TD>
</TR>
<TR>
	<TD>Genre</TD><TD>$gen</TD>
	<TD colspan=2>$newgen</TD>
</TR>
<TR>
	<TD>Year</TD><TD>$year</TD>
	<TD colspan=2>$newyear</TD>
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