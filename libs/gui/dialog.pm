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
use mp3;

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

sub show_properties_hlist
{
	my $ff = shift;

	&main::quit("show_properties_hlist: \$ff is undef") if ! defined $ff;
	&main::quit("show_properties_hlist: \$ff eq ''") if $ff eq '';
	&main::quit("show_properties_hlist: '$ff' is not a dir or file") if ! -f $ff && ! -d $ff;

	my $row = 1;

	my $top = $main::mw->Toplevel();
	$top->title('File Properties (HList)');

	# Create HList widget for structured data display
	my $hlist = $top->Scrolled
	(
		'HList',
		-scrollbars=>	'osoe',
		-columns=>		2,
		-header=>		1,
		-font=>			$config::dialog_font,
		-height=>		20,
		-width=>		80,
	)
	->grid
	(
		-row=>			$row++,
		-column=>		1,
		-columnspan=>	2,
		-sticky=>		'nsew'
	);

	# Set column headers
	$hlist->header('create', 0, -text=> 'Property');
	$hlist->header('create', 1, -text=> 'Value');

	$top->Button
	(
		-text=>				'Close',
		-activebackground=>	'white',
		-command=> 
		sub 
		{ 
			# Clear HList contents before destroying to prevent cursor issues
			$hlist->delete('all');
			destroy $top; 
		}
	)
	->grid
	(
		-row=>			$row++,
		-column=>		1,
		-columnspan=>	2
	);

	# Configure grid weights for resizing
	$top->gridRowconfigure(0, -weight=> 1);
	$top->gridColumnconfigure(0, -weight=> 1);

	# Populate data
	my $entry_num = 0;

	# Handle files vs directories differently
	if(-f $ff)
	{
		# File: show size and date
		my $size = stat($ff)->size;
		my $ff_date = ctime(stat($ff)->mtime);

		# Add basic file info
		$hlist->add($entry_num, -text=> 'File');
		$hlist->itemCreate($entry_num, 1, -text=> $ff);
		$entry_num++;

		$hlist->add($entry_num, -text=> 'Size');
		$hlist->itemCreate($entry_num, 1, -text=> $size);
		$entry_num++;

		$hlist->add($entry_num, -text=> 'Date Created');
		$hlist->itemCreate($entry_num, 1, -text=> $ff_date);
		$entry_num++;

		# Add separator
		$hlist->add($entry_num, -text=> ' ');
		$hlist->itemCreate($entry_num, 1, -text=> '');
		$entry_num++;

		# If it's a JPEG and EXIF module is available, show EXIF data
		if($ff =~ /\.jpe?g$/i && is_exif_available())
		{
			if(has_exif_data($ff))
			{
				# Add EXIF header
				$hlist->add($entry_num, -text=> 'EXIF Data');
				$hlist->itemCreate($entry_num, 1, -text=> '');
				$entry_num++;

				my $exif_tags = list_exif_tags($ff);
				for my $tag (sort keys %$exif_tags)
				{
					my $value = $exif_tags->{$tag} // '';
					# Truncate very long values for display
					if(length($value) > 100)
					{
						$value = substr($value, 0, 97) . "...";
					}

					$hlist->add($entry_num, -text=> $tag);
					$hlist->itemCreate($entry_num, 1, -text=> $value);
					$entry_num++;
				}
			}
		}

		# If it's an audio file, show ID3 tags
		if($ff =~ /\.$config::id3_ext_regex$/i)
		{
			my $id3_tags = mp3::get_tags($ff);
			
			# Check if any ID3 tags exist (not all empty)
			my $has_id3_data = 0;
			for my $tag_name (keys %$id3_tags)
			{
				if($id3_tags->{$tag_name} && $id3_tags->{$tag_name} ne '')
				{
					$has_id3_data = 1;
					last;
				}
			}
			
			if($has_id3_data)
			{
				# Add ID3 header
				$hlist->add($entry_num, -text=> 'ID3 Tags');
				$hlist->itemCreate($entry_num, 1, -text=> '');
				$entry_num++;

				# Display ID3 tags in a specific order (artist, title, album, etc.)
				my @tag_order = qw(artist title album track year genre comment);
				for my $tag_name (@tag_order)
				{
					my $value = $id3_tags->{$tag_name} // '';
					next if $value eq '';  # Skip empty tags
					
					# Capitalize first letter of tag name for display
					my $display_name = ucfirst($tag_name);
					
					$hlist->add($entry_num, -text=> $display_name);
					$hlist->itemCreate($entry_num, 1, -text=> $value);
					$entry_num++;
				}
			}
		}
	}
	else
	{
		# Directory: show only date (no size info)
		my $ff_date = ctime(stat($ff)->mtime);

		$hlist->add($entry_num, -text=> 'Directory');
		$hlist->itemCreate($entry_num, 1, -text=> $ff);
		$entry_num++;

		$hlist->add($entry_num, -text=> 'Date Created');
		$hlist->itemCreate($entry_num, 1, -text=> $ff_date);
		$entry_num++;
	}
}

sub show_del_dialog
{
	my $ff	= shift;
	my $top	= $main::mw -> Toplevel();
	my $ffl	= (length $ff) + 2;

	$top->title("Confirm Delete");

	my $frm_top = $top->Frame()
	-> pack
	(
		-side=>     'top',
		-fill=>     'both',
		-expand=>   1,
		-anchor=>   'n'
	);

	my $frm_bottom = $top->Frame()
	-> pack
	(
		-side=>     'bottom',
		-fill=>     'x',
		-expand=>   0,
		-anchor=>   's'
	);

	my $txt = $frm_top->Scrolled
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
        $txt->insert('end', "\nWarning Deleting Directory - ARE YOU SURE ?\nDirectory Tree:\n\n");

        for my $f3(@config::find_arr)
        {
            $txt->insert('end', "$f3\n");
        }
    }
    else
    {
        $txt->insert('end', "Do you want to delete\n\"$ff\"\n");
    }

	$frm_bottom->Button
	(
		-text=>				"Yes",
		-activebackground=>	"white",
		-command=>			sub
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
		-side=>		"left",
		-expand=>	1,
		-fill=>		"x",
	);

	$frm_bottom->Button
	(
		-text=>				"No",
		-activebackground=>	"white",
		-command=>			
		sub
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
