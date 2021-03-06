package dialog;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;
use File::stat;
use Time::localtime;
use File::Find;


#--------------------------------------------------------------------------------------------------------------
# Show dialog
#--------------------------------------------------------------------------------------------------------------

# no plogging is this func will be called from plog at times
# also its a very simple funtion non related to renaming

sub show
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
        	-scrollbars=>'osoe',
		-wrap=>'none',
        	-font=>$config::dialog_font
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
	my $ff	= shift;

	&main::quit("show_file_prop: \$ff is undef")			if ! defined $ff;
	&main::quit("show_file_prop: \$ff eq ''")			if $ff eq '';
	&main::quit("show_file_prop: '$ff' is not a dir or file")	if ! -f $ff && ! -d $ff;

	my $row	= 1;

        my $top = $main::mw -> Toplevel();
        $top -> title('File Properties');

	my $txt = $top -> Scrolled
	(
        	'ROText',
        	-scrollbars=>'osoe',
		-wrap=>'none',
		-font=>$config::dialog_font,
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
		-text=>'Close',
		-activebackground => 'white',
		-command => sub { destroy $top; }
	)
	-> grid
	(
		-row=>$row++,
		-column=>1,
		-columnspan=>2
	);

	my @txt = ();
	my $txt_str = '';
	if(-f $ff)
	{
		my $size = stat($ff)->size;
		my $ff_date = ctime(stat($ff)->mtime);

		@txt =
		(
			"File:		$ff",
			"Size:		$size",
			"Date Created:	$ff_date",
			"",
		);
	}
	else
	{
		my $ff_date = ctime(stat($ff)->mtime);

		@txt =
		(
			"Dir:		$ff",
			"Date Created:	$ff_date",
			"",
		);
	}
	$txt_str = join("\n", @txt);
	# display text last
	$txt->menu(undef);
	$txt -> insert('end', $txt_str);
}

sub show_del_dialog
{
	my $ff = shift;
	my $top = $main::mw -> Toplevel();
	my $ffl = (length $ff) + 2;

	$top -> title("Confirm Delete");

	my $frm_top = $top -> Frame()
	-> pack
	(
		-side => 'top',
		-fill => 'both',
		-expand=> 1,
		-anchor => 'n'
	);

	my $frm_bottom = $top -> Frame()
	-> pack
	(
		-side => 'bottom',
		-fill => 'x',
		-expand=> 0,
		-anchor => 's'
	);

	my $txt = $frm_top -> Scrolled
	(
		"ROText",
		-scrollbars=>'osoe',
		-wrap=>'none',
		-font=>$config::dialog_font,
		-height=>10,
		-width=>$ffl
        )
        -> pack
	(
		-side => "top",
		-expand=> 1,
		-fill => "both",
        );

        $txt->menu(undef);

        if(-d $ff)
        {
		find(\&run_namefix::find_fix, $ff);
		$txt -> insert('end', "\nWarning Deleting Directory - ARE YOU SURE ?\nDirectory Tree:\n\n");

		for my $f3(@config::find_arr)
		{
			$txt -> insert('end', "$f3\n");
		}
        }
        else
        {
	        $txt -> insert('end', "Do you want to delete\n\"$ff\"\n");
        }

	$frm_bottom -> Button
	(
		-text=>"Yes",
		-activebackground => "white",
		-command => sub
		{
			&misc::plog(2, "Deleting $ff");
			if(-d $ff)
			{
				my @tmp = ();
				for my $f3(@config::find_arr)
				{
					if(-f $f3)
					{
						unlink($f3);
					}
					elsif(-d $f3)
					{
						push @tmp, $f3;
					}
				}
				for my $d(reverse @tmp)
				{
					rmdir($d);
				}
			}
			else
			{
				unlink($ff);
			}
			&dir::ls_dir;
			destroy $top;
		}
	)
	->pack
	(
		-side => "left",
		-expand=> 1,
		-fill => "x",
	);

	$frm_bottom -> Button
	(
		-text=>"No",
		-activebackground => "white",
		-command => sub
		{
			destroy $top;
		}
	)
	->pack
	(
		-side => "left",
		-expand=> 1,
		-fill => "x",
	);
}



1;
