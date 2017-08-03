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
	if($main::HTML_HACK)
	{
		my $string = shift;
		&misc::file_append($main::html_file, $string);
	}
	return;
}

1;