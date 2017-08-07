package manual;
require Exporter;
@ISA = qw(Exporter);


use strict;
use warnings;

# routines for manual renaming etc

sub manual::edit
{
	($config::hlist_file, $config::hlist_cwd) = $dir_hlist::hlist->info("data", $config::hlist_selection);
	my $file 	= $config::hlist_file;
	my $file_original = $file;
	my $row 		= 1;
	my $EXT		= 0;
	my $TAGS	= 0;
	my $new_fn;
	my $old_fn;
	my $new_ext;
	my $old_ext;
	my $ent_max_l 	= 50;
	my $ent_min_l 	= 2;
	my $ent_l;
	my $l 		= length $file;

	my %tag_hash	= ();

	&misc::plog(3, "sub manual::edit: \"$file\"");

       if($ent_min_l <= $l && $l <= $ent_max_l)
        {
        	$ent_l = $l;
        }
        elsif($ent_min_l > $l)
        {
        	$ent_l = $ent_min_l;
        }
        else
        {
        	$ent_l = $ent_max_l;
        }

        if(-f $file && $file =~ /^(.*)\.(.{3,4})$/)
        {
        	$new_fn = $1;
                $old_fn = $new_fn;
                $new_ext = $2;
                $old_ext = $new_ext;
                $EXT = 1;
        }


        if(!$file)
        {
        	&misc::plog(0, "sub manual::edit: \$file isnt defined.");
        	return;
        }

        $TAGS = &misc::is_in_array(lc $old_ext, \@config::id3v2_exts);

        my $tag	= "";
        my $art = "";
        my $tit = "";
        my $tra = 0;
        my $alb = "";
        my $com = "";
        my $gen = "";
        my $year = '';

	&misc::plog(4, "sub manual::edit: chdir to  \$config::hlist_cwd = \"$config::hlist_cwd\" ");
	chdir $config::hlist_cwd;	# shift to correct dir (needed for recursive mode).

	my $newfile = $file;

	my $w = $main::mw->Toplevel();
	$w->title("Manual Rename");

	$w->Label
	(
        	-text=>"Manual Rename",
        	-font=>$config::dialog_title_font
        )
        -> grid
        (
        	-row=>1,
        	-column=>1,
        	-columnspan=>1
        );

	my $frame1 = $w->Frame(-borderwidth=>1)
	->grid
	(
		-row=>2,
		-column=>1,
		-columnspan=>1
	);

	my $button_frame = $w->Frame(-borderwidth=>1)
	->grid
	(
		-row=>3,
		-column=>1,
		-columnspan=>1
	);

	$frame1->Label(-text=>"Old Filename: ")
	->grid
	(
		-row=>1,
		-column=>1
	);

        if($EXT)
        {
	        $frame1->Entry
                (
	                -textvariable=>\$old_fn,
	                -width=>$ent_l,
	                -state=>"readonly",
	        )
	        ->grid
                (
	                -row=>1,
	                -column=>2
	        );

	        $frame1->Label(-text=>" . ")
	        ->grid
	        (
	                -row=>1,
	                -column=>3
	        );

	        $frame1->Entry
                (
	                -textvariable=>\$old_ext,
	                -width=>5,
	                -state=>"readonly",
	        )
	        ->grid
                (
	                -row=>1,
	                -column=>4
	        );
        }
        else
        {
	        $frame1->Entry
                (
	                -textvariable=>\$file,
	                -width=>$ent_l,
	                -state=>"readonly",
	        )
	        ->grid
                (
	                -row=>1,
	                -column=>2
	        );
	}

	$frame1->Label(-text=>"New Filename: ")
	->grid
	(
		-row=>2,
		-column=>1
	);

        if($EXT)
        {
	        $frame1->Entry
                (
	                -textvariable=>\$new_fn,
	                -width=>$ent_l
	        )
	        ->grid
	        (
	                -row=>2,
	                -column=>2
	        );
	        $frame1->Label(-text=>" . ")
	        ->grid
	        (
	                -row=>2,
	                -column=>3
	        );
	        $frame1->Entry
                (
	                -textvariable=>\$new_ext,
	                -width=>5
	        )
	        ->grid
	        (
	                -row=>2,
	                -column=>4
	        );
        }
        else
        {
	        $frame1->Entry
	        (
	                -textvariable=>\$newfile,
	                -width=>$ent_l
	        )
	        ->grid
	        (
	                -row=>2,
	                -column=>2
	        );
	}
	if($TAGS)
	{
		&misc::plog(4, "sub manual::edit: \"$file\" is a mp3, using mp3 rename gui ");
        	my $ref = &mp3::get_tags($file);
        	%tag_hash = %$ref;
        	$frame1->Label(-text=>"Artist: ")
		->grid
		(
			-row=>3,
			-column=>1
		);

	        $frame1->Entry
	        (
                	-textvariable=>\$tag_hash{artist},
                        -width=>30
        	)
	        ->grid
	        (
                	-row=>3,
                        -column=>2,
                        -sticky=>"nw",
                        -columnspan=>3
        	);

        	$frame1->Label(-text=>"Track: ")
		->grid
		(
			-row=>4,
			-column=>1
		);

	        $frame1->Entry
	        (
                	-textvariable=>\$tag_hash{track},
                        -width=>2
        	)
	        ->grid
	        (
                	-row=>4,
                        -column=>2,
                        -sticky=>"nw",
                        -columnspan=>3
        	);

        	$frame1->Label(-text=>"Title: ")
		->grid
		(
			-row=>5,
			-column=>1
		);

		$frame1->Entry
		(
                	-textvariable=>\$tag_hash{title},
                        -width=>30
        	)
	        ->grid
	        (
                	-row=>5,
                        -column=>2,
                        -sticky=>"nw",
                        -columnspan=>3
        	);

                $frame1->Label
                (
			-text=>"Album: "
		)
		->grid
		(
			-row=>6,
			-column=>1
		);

		$frame1->Entry
                (
                	-textvariable=>\$tag_hash{album},
                        -width=>30,
        	)
	        ->grid
	        (
                	-row=>6,
                        -column=>2,
                        -sticky=>"nw",
                        -columnspan=>3
        	);

                $frame1->Label(-text=>"Genre: ")
		->grid
                (
			-row=>7,
			-column=>1
		);

                $frame1->JComboBox
                (
 	                -mode=>'readonly',
	                -relief=>'groove',
	                -textvariable =>\$tag_hash{genre},
	                -choices=>\@config::genres,
	                -entrywidth=>16,
		)
	        -> grid
                (
	                -row=>7,
	                -column=>2,
	                -sticky=>"nw",
                        -columnspan=>3
		);

                $frame1->Label(-text=>"Year: ")
		->grid
		(
			-row=>8,
			-column=>1
		);

	        $frame1->Entry
                (
                	-textvariable=>\$tag_hash{year},
                        -width=>30
        	)
	        ->grid
                (
                	-row=>8,
                        -column=>2,
                        -sticky=>"nw",
			-columnspan=>3
        	);

                $frame1->Label(-text=>"comment: ")
		->grid
		(
			-row=>9,
			-column=>1
		);

	        $frame1->Entry
                (
                	-textvariable=>\$tag_hash{comment},
                        -width=>30
        	)
	        ->grid
                (
                	-row=>9,
                        -column=>2,
                        -sticky=>"nw",
                        -columnspan=>3
        	);

	}
	my $but_reset = $button_frame -> Button
	(
        	-text=>"Reset",
        	-activebackground=>'white',
        	-command => sub
        	{
        		$newfile = $file = $file_original;
                        $new_fn = $old_fn;
                        $new_ext = $old_ext;

                        if($TAGS)
                        {
				my $ref = &mp3::get_tags($file);
				%tag_hash = %$ref;
			}
        	}
        )
        -> grid
        (
        	-row => 4,
        	-column => 1,
        	-columnspan => 1
        );

	if ($TAGS)
        {
	        $button_frame -> Button
	        (
	                -text=>"Guess Tag",
	                -activebackground=>'white',
	                -command => sub
	                {
                        	($tag_hash{artist}, $tag_hash{track}, $tag_hash{title}, $tag_hash{album}) = &mp3::guess_tags($file);
				print "button\n";
	                }
	        )
	        -> grid
	        (
	                -row => 4,
	                -column => 2,
	                -columnspan => 1
	        );
	}

	my $but_apply = $button_frame -> Button
	(
        	-text=>"Apply",
        	-activebackground=>'white',
        	-command => sub
        	{
                        if($TAGS)
			{
				&mp3::write_tags($file, \%tag_hash);
			}

                	if($EXT)
                        {
				$newfile = "$new_fn.$new_ext";
				$old_fn = $new_fn;
				$old_ext = $new_ext;
                        }
				&me_rename($file, $newfile);
                                $file = $newfile;
		}
        )
        -> grid
	(
        	-row => 4,
        	-column => 3,
        	-columnspan => 1
        );

	my $but_close = $button_frame -> Button
	(
        	-text=>"Close",
        	-activebackground=>'white',
        	-command => sub
		{
        		destroy $w;
			if($config::MR_DONE)
			{
				$config::MR_DONE = 0;
                        	&dir::ls_dir;
			}
        	}
        )
        -> grid
        (
        	-row=>4,
        	-column=>4,
        	-columnspan=>1
        );

        $w->update();
        $w->resizable(0,0);

	return;
}

sub me_rename
{
	my $file = shift;
	my $newfile = shift;
	$config::MR_DONE = 1;

        if($file eq $newfile)
        {
        	return;
        }

	if($config::hash{fat32fix}{value})
	{
		my $tmpfile = $file."tmp";

		if(-f $tmpfile)
		{
			&misc::plog(0, "sub me_rename: tmpfile: $tmpfile exists.");
			return 0;
		}
		rename $file, $tmpfile;
		rename $tmpfile, $newfile;
	}
	else
	{
		if(-f $newfile)
		{
			&misc::plog(0, "sub me_rename: newfile: $newfile exists");
			return 0;
		}
		rename $file, $newfile;
	}
}

1;
