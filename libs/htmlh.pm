package htmlh;	# htmlhack
require Exporter;
@ISA = qw(Exporter);


use strict;
use warnings;

#--------------------------------------------------------------------------------------------------------------
# html_hack
#--------------------------------------------------------------------------------------------------------------

sub html
{
	if($config::hash{HTML_HACK}{value})
	{
		my $string = shift;
		&misc::file_append($main::html_file, $string);
	}
	return;
}

1;