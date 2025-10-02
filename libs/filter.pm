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
	return 1 if $config::hash{'filter_string'}{value} eq '';

	my $string	= shift;
	my $filt	= $config::hash{'filter_string'}{value};

	&misc::plog(3, "sub match: \"$string\"");

	if($string eq '')
	{
		&misc::plog(0, "sub match: ERROR: blank file passed");
		return 1;
	}

	if(!$config::hash{filter_regex}{value})
	{
		&misc::plog(4, "sub match: regexp disabled, using escaped string");
		$filt = quotemeta $config::hash{'filter_string'}{value};
	}

	if
	(
		( $config::hash{filter_ignore_case}{value} && $string =~ /$filt/) ||
		(!$config::hash{filter_ignore_case}{value} && $string =~ /$filt/i)
	)
	{
		&misc::plog(4, "sub match: string \"$string\" matched filter \"$filt\"");
		return 1;
	}
	
	&misc::plog(4, "sub match: string \"$string\" failed matched filter \"$filt\"");
	return 0;
}

1;
