package dialog;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;
use File::stat;
use Time::localtime;
use File::Find;

# Add libs directory to path for jpegexif module
use FindBin;
use lib "$FindBin::Bin/../../libs";
use jpegexif;

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
        -scrollbars=>   'osoe',
		-wrap=>         'none',
        -font=>         $config::dialog_font
    )
    -> grid
	(
        -row=>          $row++,
        -column=>       1,
        -columnspan=>   2
    );

    $txt->menu(undef);
    $txt->insert('end', "$text");

    $top -> Button
    (
        -text=>             "Close",
        -activebackground=> "white",
        -command=>          sub
        {
            destroy $top;
        }
    )
    -> grid
    (
        -row=>          $row++,
        -column=>       1,
        -columnspan=>   2
    );

	$top->resizable(0,0);
}

sub show_file_prop
{
	my $ff	= shift;

	&main::quit("show_file_prop: \$ff is undef")			    if ! defined $ff;
	&main::quit("show_file_prop: \$ff eq ''")			        if $ff eq '';
	&main::quit("show_file_prop: '$ff' is not a dir or file")	if ! -f $ff && ! -d $ff;

	my $row	= 1;

    my $top = $main::mw -> Toplevel();
    $top->title('File Properties');

	my $text = $top->Scrolled
	(
        'ROText',
        -scrollbars=>   'osoe',
		-wrap=>         'none',
		-font=>         $config::dialog_font,
		-height=>      15,
	)
	-> grid
	(
		-row=>          $row++,
		-column=>       1,
		-columnspan=>   2
	);

    $top->Button
	(
		-text=>             'Close',
		-activebackground=> 'white',
		-command=>          sub { destroy $top; }
	)
	->grid
	(
		-row=>          $row++,
		-column=>       1,
		-columnspan=>   2
	);

	my @txt = ();
	my $txt_str = '';

	# Handle files vs directories differently (already validated at line 75)
	if(-f $ff)
	{
		# File: show size and date
		my $size = stat($ff)->size;
		my $ff_date = ctime(stat($ff)->mtime);

		@txt =
		(
			"File:\t\t$ff",
			"Size:\t\t$size",
			"Date Created:\t$ff_date",
			"",
		);

		# If it's a JPEG and EXIF module is available, show EXIF data
		if($ff =~ /\.jpe?g$/i && is_exif_available())
		{
			if(has_exif_data($ff))
			{
				push @txt, "\nEXIF Data:";
				push @txt, "-" x 40;
				
				my $exif_tags = list_exif_tags($ff);

				# --- Advanced Padding for Stable Alignment ---
				# 1. Find the length of the longest tag to determine alignment target
				my $max_len = 0;
				for my $tag (keys %$exif_tags) {
					$max_len = length($tag) if length($tag) > $max_len;
				}

				# 2. Set alignment target just beyond the longest tag (at the next tab stop)
				my $tab_width = 8;
				my $align_col = (int($max_len / $tab_width) + 1) * $tab_width;

				for my $tag (sort keys %$exif_tags)
				{
					my $value = $exif_tags->{$tag} // '';
					# Truncate very long values for display
					if(length($value) > 50)
					{
						$value = substr($value, 0, 47) . "...";
					}
					
					# 3. Calculate padding using a mix of tabs and spaces
					my $len = length($tag);
					my $spaces_to_align = $align_col - $len;
					my $padding = "\t"; # Always start with at least one tab
					if ($spaces_to_align > $tab_width) 
					{
						# If more than one tab stop away, add more tabs
						$padding .= "\t" x int(($spaces_to_align - 1) / $tab_width);
					}

					push @txt, "$tag$padding$value";
				}
			}
			push @txt, "";
		}
	}
	else
	{
		# Directory: show only date (no size info)
		my $ff_date = ctime(stat($ff)->mtime);

		@txt =
		(
			"Dir:\t\t$ff",
			"Date Created:\t$ff_date",
			"",
		);
	}
	$txt_str = join("\n", @txt);
	# display text last
	$text->menu(undef);
	$text->insert('end', $txt_str);
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
		-side=>     'top',
		-fill=>     'both',
		-expand=>   1,
		-anchor=>   'n'
	);

	my $frm_bottom = $top -> Frame()
	-> pack
	(
		-side=>     'bottom',
		-fill=>     'x',
		-expand=>   0,
		-anchor=>   's'
	);

	my $txt = $frm_top -> Scrolled
	(
		"ROText",
		-scrollbars=>   'osoe',
		-wrap=>         'none',
		-font=>         $config::dialog_font,
		-height=>       10,
		-width=>        $ffl
    )
    -> pack
    (
        -side=>     "top",
        -expand=>   1,
        -fill=>     "both",
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
		-text=>             "Yes",
		-activebackground=> "white",
		-command=>          sub
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
		-side=>     "left",
		-expand=>   1,
		-fill=>     "x",
	);

	$frm_bottom -> Button
	(
		-text=>             "No",
		-activebackground=> "white",
		-command=>          sub
		{
			destroy $top;
		}
	)
	->pack
	(
		-side=>     "left",
		-expand=>   1,
		-fill=>     "x",
	);
}



1;
