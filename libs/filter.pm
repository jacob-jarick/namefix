#!/usr/bin/perl

use strict;
use warnings;

# returns 1 if string matches current filter
# currently in namefix gui filter is always on, it always returns a positive match
# if the filter is blank

sub match_filter
{
	my $string = shift;
	my $filt = "";

	if($main::filter_string eq "")
	{
		return 1;
	}

	&plog(3, "sub match_filter: \"$string\"");

	if($string eq "")
	{
		&plog(0, "sub match_filter: ERROR: blank file passed");
		return 1;
	}

	if($string eq "..")
	{
		&plog(4, "sub match_filter: got .. passed");
		return 1;
	}

	$filt = $main::filter_string;
	if($main::disable_regexp == 1)
	{
		&plog(4, "sub match_filter: regexp disabled, using escaped string");
		$filt = $main::filter_string_escaped;
	}

	if
	(
		($main::filter_cs == 1 && $string =~ /.*($filt).*/) ||
		($main::filter_cs == 0 && $string =~ /.*($filt).*/i)
	) 
	{
		&plog(4, "sub match_filter: string \"$string\" matched filter \"$filt\"");
		return 1;
	}
	&plog(4, "sub match_filter: string \"$string\" failed matched filter \"$filt\"");
        return 0;
}

1;