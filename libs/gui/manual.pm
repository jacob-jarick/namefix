package manual;
require Exporter;
@ISA = qw(Exporter);


use strict;
use warnings;

# routines for manual renaming etc

sub manual_edit
{
	($main::hlist_file, $main::hlist_cwd) = $dir_hlist::hlist->info("data", $main::hlist_selection);
	my $file 	= $main::hlist_file;
	my $file_original = $file;
	my $row 		= 1;
	my $EXT		= 0;
	my $new_fn;
	my $old_fn;
	my $new_ext;
	my $old_ext;
	my $ent_max_l 	= 50;
	my $ent_min_l 	= 2;
	my $ent_l;
	my $l 		= length $file;

	&misc::plog(3, "sub manual_edit: \"$file\"");

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

        if(!$file) {
        	&misc::plog(0, "sub manual_edit: \$file isnt defined.");
        	return;
        }

        my $tag	= "";
        my $art = "";
        my $tit = "";
        my $tra = "";
        my $alb = "";
        my $com = "";
        my $gen = "";
        my $year = "";

	&misc::plog(4, "sub manual_edit: chdir to  \$main::hlist_cwd = \"$main::hlist_cwd\" ");
	chdir $main::hlist_cwd;	# shift to correct dir (needed for recursive mode).

	my $newfile = $file;

	my $w = $main::mw->Toplevel();
	$w->title("Manual Rename");

	$w->Label(
        	-text=>"Manual Rename",
        	-font=>$main::dialog_title_font
        )
        -> grid(
        	-row=>1,
        	-column=>1,
        	-columnspan=>1
        );

	my $frame1 = $w->Frame(
		-borderwidth=>1
	)
	->grid(
		-row=>2,
		-column=>1,
		-columnspan=>1
	);

	my $button_frame = $w->Frame(
		-borderwidth=>1
	)
	->grid(
		-row=>3,
		-column=>1,
		-columnspan=>1
	);

	$frame1->Label(
		-text=>"Old Filename: "
	)
	->grid(
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

	        $frame1->Label(
	                -text=>" . "
	        )
	        ->grid(
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

	$frame1->Label(
		-text=>"New Filename: "
	)
	->grid(
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
	        ->grid(
	                -row=>2,
	                -column=>2
	        );
	        $frame1->Label(
	                -text=>" . "
	        )
	        ->grid(
	                -row=>2,
	                -column=>3
	        );
	        $frame1->Entry
                (
	                -textvariable=>\$new_ext,
	                -width=>5
	        )
	        ->grid(
	                -row=>2,
	                -column=>4
	        );
        }
        else
        {
	        $frame1->Entry(
	                -textvariable=>\$newfile,
	                -width=>$ent_l
	        )
	        ->grid(
	                -row=>2,
	                -column=>2
	        );
	}
	if($file =~ /.*\.mp3$/i) {
		&misc::plog(4, "sub manual_edit: \"$file\" is a mp3, using mp3 rename gui ");
        	($tag, $art, $tit, $tra, $alb, $com, $gen, $year) = &get_tags($file);
        	$frame1->Label(
			-text=>"Artist: "
		)
		->grid(
			-row=>3,
			-column=>1
		);

	        $frame1->Entry(
                	-textvariable=>\$art,
                        -width=>30
        	)
	        ->grid(
                	-row=>3,
                        -column=>2,
                        -sticky=>"nw",
                        -columnspan=>3
        	);

        	$frame1->Label(
			-text=>"Track: "
		)
		->grid(
			-row=>4,
			-column=>1
		);

	        $frame1->Entry(
                	-textvariable=>\$tra,
                        -width=>2
        	)
	        ->grid(
                	-row=>4,
                        -column=>2,
                        -sticky=>"nw",
                        -columnspan=>3
        	);

        	$frame1->Label(
			-text=>"Title: "
		)
		->grid(
			-row=>5,
			-column=>1
		);

		$frame1->Entry(
                	-textvariable=>\$tit,
                        -width=>30
        	)
	        ->grid(
                	-row=>5,
                        -column=>2,
                        -sticky=>"nw",
                        -columnspan=>3
        	);

                $frame1->Label(
			-text=>"Album: "
		)
		->grid(
			-row=>6,
			-column=>1
		);

		$frame1->Entry
                (
                	-textvariable=>\$alb,
                        -width=>30,
        	)
	        ->grid(
                	-row=>6,
                        -column=>2,
                        -sticky=>"nw",
                        -columnspan=>3
        	);

                $frame1->Label
                (
			-text=>"Genre: "
		)
		->grid
                (
			-row=>7,
			-column=>1
		);

                $frame1->JComboBox
                (
 	                -mode=>'readonly',
	                -relief=>'groove',
	                -textvariable =>\$gen,
	                -choices=>\@main::genres,
	                -entrywidth=>16,
		)
	        -> grid
                (
	                -row=>7,
	                -column=>2,
	                -sticky=>"nw",
                        -columnspan=>3
		);

                $frame1->Label(
			-text=>"Year: "
		)
		->grid(
			-row=>8,
			-column=>1
		);

	        $frame1->Entry
                (
                	-textvariable=>\$year,
                        -width=>30
        	)
	        ->grid
                (
                	-row=>8,
                        -column=>2,
                        -sticky=>"nw",
			-columnspan=>3
        	);

                $frame1->Label(
			-text=>"comment: "
		)
		->grid(
			-row=>9,
			-column=>1
		);

	        $frame1->Entry
                (
                	-textvariable=>\$com,
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
	my $but_reset = $button_frame -> Button(
        	-text=>"Reset",
        	-activebackground=>'white',
        	-command => sub {
        		$newfile = $file = $file_original;
                        $new_fn = $old_fn;
                        $new_ext = $old_ext;

                        if(
                        	$main::id3_mode == 1 &&
                                $file =~ /.*\.mp3/i
			) {
                        	($tag, $art, $tit, $tra, $alb, $com, $gen, $year) = &get_tags($file);
                          }
        	}
        )
        -> grid(
        	-row => 4,
        	-column => 1,
        	-columnspan => 1
        );

        if(
        	$main::id3_mode == 1 &&
		$file =~ /.*\.mp3$/i
        ) {
	        $button_frame -> Button(
	                -text=>"Guess Tag",
	                -activebackground=>'white',
	                -command => sub {
                        	($art, $tra, $tit, $alb) = &guess_tags($file);
				print "button\n";
	                }
	        )
	        -> grid(
	                -row => 4,
	                -column => 2,
	                -columnspan => 1
	        );
	}

	my $but_apply = $button_frame -> Button(
        	-text=>"Apply",
        	-activebackground=>'white',
        	-command => sub {
                	if($EXT)
                        {
        			&me_rename($file, "$new_fn.$new_ext");
                                $old_fn = $new_fn;
                                $old_ext = $new_ext;
                        }
                        else
                        {
                        	&me_rename($file, $newfile);
                                $file = $newfile;
                        }
                        if(
                        	$main::id3_mode == 1 &&
                                $file =~ /.*\.mp3$/i
                        ) {
                        	&write_tags($file, $art, $tit, $tra, $alb, $com, $gen, $year);
                        }
        	}
        )
        -> grid(
        	-row => 4,
        	-column => 3,
        	-columnspan => 1
        );

	my $but_close = $button_frame -> Button(
        	-text=>"Close",
        	-activebackground=>'white',
        	-command => sub
		{
        		destroy $w;
			if($main::MR_DONE)
			{
				$main::MR_DONE = 0;
                        	&dir::ls_dir;
			}
        	}
        )
        -> grid(
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
	$main::MR_DONE = 1;

        if($file eq $newfile)
        {
        	return;
        }

	if($main::fat32fix)
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