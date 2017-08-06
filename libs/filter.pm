package filter;
require Exporter;
@ISA = qw(Exporter);


use strict;
use warnings;

# returns 1 if string matches current filter
# currently in namefix gui filter is always on, it always returns a positive match
# if the filter is blank

sub match
{
	my $string = shift;
	my $filt = "";

	if($main::filter_string eq "")
	{
		return 1;
	}

	&misc::plog(3, "sub match: \"$string\"");

	if($string eq "")
	{
		&misc::plog(0, "sub match: ERROR: blank file passed");
		return 1;
	}

	if($string eq "..")
	{
		&misc::plog(4, "sub match: got .. passed");
		return 1;
	}

	$filt = $main::filter_string;
	if($config::hash{FILTER_REGEX}{value} == 0)
	{
		&misc::plog(4, "sub match: regexp disabled, using escaped string");
		$filt = quotemeta $filt;
	}

	if
	(
		($main::FILTER_IGNORE_CASE == 1 && $string =~ /.*($filt).*/) ||
		($main::FILTER_IGNORE_CASE == 0 && $string =~ /.*($filt).*/i)
	)
	{
		&misc::plog(4, "sub match: string \"$string\" matched filter \"$filt\"");
		return 1;
	}
	&misc::plog(4, "sub match: string \"$string\" failed matched filter \"$filt\"");
        return 0;
}

1;