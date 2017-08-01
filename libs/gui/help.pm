#--------------------------------------------------------------------------------------------------------------
# Show about box
#--------------------------------------------------------------------------------------------------------------

use strict;
use warnings;

sub show_help 
{
my $help_text =
"Welcome to the very basic help txt:

DEBUG LEVELS:
0	ERROR
1	warnings & startup messages
2	not used
3	Sub routine called
4	Important but noisy sub details
5	Very noisy sub details
";

	&show_dialog("Help", $help_text);
}

1;