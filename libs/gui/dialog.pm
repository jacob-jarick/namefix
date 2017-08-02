use strict;
use warnings;
use File::stat;
use Time::localtime;

#--------------------------------------------------------------------------------------------------------------
# Show dialog
#--------------------------------------------------------------------------------------------------------------

# no plogging is this func will be called from plog at times
# also its a very simple funtion non related to renaming

sub show_dialog
{
	my $title = shift;
	my $text = shift;

	if(!$text)
	{
		return 0;
	}

	my $row	= 1;

        my $top = $main::mw -> Toplevel();
        $top -> title("$title");

        my $txt = $top -> Scrolled
	(
        	"ROText",
        	-scrollbars=>"osoe",
		-wrap=>'none',
        	-font=>$main::dialog_font
        )
        -> grid
	(
        	-row => $row++,
        	-column => 1,
        	-columnspan => 2
        );

        $txt->menu(undef);
        $txt -> insert('end', "$text");

        $top -> Button
	(
        	-text=>"Close",
        	-activebackground => "white",
        	-command => sub
		{
        		destroy $top;
        	}
        )
        -> grid
	(
        	-row => $row++,
        	-column => 1,
        	-columnspan => 2
        );

	$top->resizable(0,0);
}

sub show_file_prop
{
	my $title = "File Properties";
	my $text = "";
	my $ff = shift;

	my $row	= 1;

        my $top = $main::mw -> Toplevel();
        $top -> title("$title");

	my $txt = $top -> Scrolled
	(
        		"ROText",
        		-scrollbars=>"osoe",
		-wrap=>'none',
		-font=>$main::dialog_font,
		-height=>5,
	)
	-> grid
	(
		-row => $row++,
		-column => 1,
		-columnspan => 2
	);

        $top -> Button
	(
		-text=>"Close",
		-activebackground => "white",
		-command => sub
		{
			destroy $top;
		}
	)
	-> grid
	(
		-row => $row++,
		-column => 1,
		-columnspan => 2
	);

#	$top->resizable(0,0);


	my $size = stat($ff)->size;
	my $ff_date = ctime(stat($ff)->mtime);

	my @txt =
	(
		"File:		$ff",
		"Size:		$size",
		"Date Created:	$ff_date",
		"",
	);

	my $txt_str = join("\n", @txt);

	# display text last
	$txt->menu(undef);
	$txt -> insert('end', "$txt_str");


}


sub show_del_dialog
{
	my $ff = shift;
	my $top = $main::mw -> Toplevel();
	my $ffl = (length $ff) + 2;

	$top -> title("Confirm Delete");

	my $txt = $top -> Scrolled
	(
		"ROText",
		-scrollbars=>"osoe",
		-wrap=>'none',
		-font=>$main::dialog_font,
		-height=>4,
		-width=>$ffl
        )
        -> grid
	(
        		-row => 1,
        		-column => 1,
        		-columnspan => 2
        );

        $txt->menu(undef);
        $txt -> insert('end', "Do you want to delete\n\"$ff\"");

	$top -> Button
	(
        		-text=>"Yes",
        		-activebackground => "white",
        		-command => sub
		{
			unlink($ff);
			&dir::ls_dir;
			destroy $top;

		}
	)
	-> grid
	(
		-row => 2,
        		-column => 1,
	);

	$top -> Button
	(
		-text=>"No",
		-activebackground => "white",
		-command => sub
		{
			destroy $top;
		}
	)
	-> grid
	(
		-row => 2,
		-column => 2,
	);
}



1;