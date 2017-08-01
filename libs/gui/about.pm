#--------------------------------------------------------------------------------------------------------------
# Show about box
#--------------------------------------------------------------------------------------------------------------

use strict;
use warnings;

sub show_about 
{
my $help_text = join("", &readf($main::about));

	my $row = 1;
        my $top = $main::mw -> Toplevel();
        $top -> title('About');

	my $image = $main::mw->Photo
	(
		-format=>'jpeg',
		-file=>$main::mempic
	);

	$top->Label
	(
		-image =>$image
	)
	-> grid
	(
		-row=>2,
		-column=>1
	);

        my $txt = $top -> Scrolled
	(
        	'ROText',
        	-scrollbars=>'osoe',
		-wrap=>"word",
        	-font=>$main::dialog_font,
        	-width=>60,
        	-height=>18
        )
        -> grid
	(
        	-row=>2,
        	-column=>2
        );
        $txt->menu(undef);
        $txt -> insert
	(
        	'end',
        	$help_text
        );

        $top -> Button
	(
        	-text=>"Close",
        	-activebackground=>'cyan',
        	-command => sub 
		{
        		destroy $top;
        	}
        )
        -> grid
	(
        	-row => 4,
        	-column => 1,
        	-columnspan => 2
        );

        $top->update();
        $top->resizable(0,0);
}

1;