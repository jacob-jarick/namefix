use strict;
use warnings;

#--------------------------------------------------------------------------------------------------------------
# Show Todo
#--------------------------------------------------------------------------------------------------------------

sub show_todo
{
	my $todo_txt = join("", &misc::readf($main::todo));

        my $top = $main::mw -> Toplevel();
        $top -> title("Todo List");

        my $top_lab = $top -> Label
	(
        	-text=>"Todo List for Namefix.pl $main::version",
        	-font=>$main::dialog_title_font
        ) -> grid(
        	-row => 1,
        	-column => 1,
        	-columnspan => 2
        );

        my $txt = $top -> Scrolled
	(
        	"ROText",
        	-scrollbars=>"osoe",
        	-font=>$main::dialog_font
        )
        -> grid
	(
        	-row => 2,
        	-column => 1,
        	-columnspan => 2
        );

        $txt->menu(undef);
        $txt -> insert('end', "$todo_txt");

        my $but_close = $top -> Button(
        	-text=>"Close",
        	-activebackground => "white",
        	-command => sub {
        		destroy $top;
        	}
        )
        -> grid(
        	-row => 4,
        	-column => 1,
        	-columnspan => 2
        );

	$top->resizable(0,0);
}

1;