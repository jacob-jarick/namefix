use strict;
use warnings;

#--------------------------------------------------------------------------------------------------------------
# clear list
#--------------------------------------------------------------------------------------------------------------

sub hlist_clear
{
	$main::hl_counter = 0;
	$main::hlist2->delete("all");

	return 1;
}

#--------------------------------------------------------------------------------------------------------------
# hlist right click menu
#--------------------------------------------------------------------------------------------------------------

sub show_rc_menu
{
	&plog(3, "sub show_rc_menu ");
	my ($x, $y) = $main::mw->pointerxy;

	my $s = $main::hlist2->nearest($y - $main::hlist2->rooty);
	$main::hlist2->selectionClear();
	$main::hlist2->selectionSet($s);
	$main::hlist_selection = $s;
	$main::rc_menu->post($x,$y);
}

sub hide_rc_menu
{
	&plog(3, "sub hide_rc_menu ");
	my ($l,$m)=@_;
	$m->unpost();
}

#--------------------------------------------------------------------------------------------------------------
# draw list
#--------------------------------------------------------------------------------------------------------------

sub hlist_cd
{
	my $file = shift;
	my $wd = shift;
	my $old = $main::dir;
	my $path = $wd . "/" . "$file";

	&plog(3, "sub hlist_cd: \"$file\"");
	&plog(4, "sub hlist_cd: \$path = \"$path\"");

        if(-d $path)
	{
        	$main::dir = $path;
                if(chdir $main::dir)
		{
			$main::dir = cwd();
	        	&ls_dir;
	        	return;
		}
		&plog(4, "sub hlist_cd: couldnt chdir to $main::dir");
		&plog(4, "sub hlist_cd: setting \$main::dir to old value \"$old\"");
		$main::dir = $old;
        }
	&plog(4, "sub hlist_cd: \$path not a valid directory ignoring");
        # not a valid path, ignore
        return;
}

#--------------------------------------------------------------------------------------------------------------
# hlist_update
#--------------------------------------------------------------------------------------------------------------
# called from various subs that need updates, update is delayed n times for speedups.

sub fn_update_delay
{
	$main::update_delay--;
	if($main::update_delay == 0 || $main::LISTING == 0)
	{
		$main::mw->update();
		$main::update_delay = $main::delay;
	}
}

#--------------------------------------------------------------------------------------------------------------
# draw list
#--------------------------------------------------------------------------------------------------------------

sub draw_list
{
	&plog(3, "sub draw_list ");
	my $columns = 4;
	if($main::id3_mode == 1)
	{
		$columns = 18;
	}

	if($main::hlist2)
	{
		$main::hlist2->destroy;
	}

        our $hlist2 = $main::frm_right2 -> Scrolled
        (
		"HList",
		-scrollbars=>"osoe",
		-header => 1,
		-columns=>$columns,
		-selectbackground => 'Cyan',
		-browsecmd => sub
		{
                	# when user clicks on an entry update global variables
               		$main::hlist_selection = shift;
               		($main::hlist_file, $main::hlist_cwd, $main::hlist_file_new) = $main::hlist2->info("data", $main::hlist_selection);
               	},
		-command=> sub
		{
                	# user has double clicked
			&hlist_cd($main::hlist_file, $main::hlist_cwd);
		}
	)
	->pack
	(
        	-side=>'bottom',
		-expand=>1,
		-fill=>'both'
	);
	$main::hlist2->header('create', 0, -text =>' ');		# these 2 columns are the same
	$main::hlist2->header('create', 1, -text =>'Filename');      # for norm & id3 mode

	if($main::id3_mode == 1)
	{
		$main::hlist2->header('create', 2, -text => 'Artist');
		$main::hlist2->header('create', 3, -text => 'Track');
		$main::hlist2->header('create', 4, -text => 'Title');
		$main::hlist2->header('create', 5, -text => 'Album');
		$main::hlist2->header('create', 6, -text => 'Genre');
		$main::hlist2->header('create', 7, -text => 'Year');
		$main::hlist2->header('create', 8, -text => 'Comment');

		$main::hlist2->header('create', 9, -text => '#');
		$main::hlist2->header('create', 10, -text => 'New Filename');
		$main::hlist2->header('create', 11, -text => 'New Artist');
		$main::hlist2->header('create', 12, -text => 'New Track');
		$main::hlist2->header('create', 13, -text => 'New Title');
		$main::hlist2->header('create', 14, -text => 'New Album');
		$main::hlist2->header('create', 15, -text => 'New Genre');
		$main::hlist2->header('create', 16, -text => 'New Year');
		$main::hlist2->header('create', 17, -text => 'New Comment');
	}
	else
	{
		$main::hlist2->header('create', 2, -text => '#');
		$main::hlist2->header('create', 3, -text => 'New Filename');
	}

        our $rc_menu = $main::hlist2->Menu(-tearoff=>0);
        $rc_menu -> command
        (
		-label=>"Properties",
		-underline=> 1,
		-command=> sub
		{
			print "Stub Properties $main::hlist_file, $main::hlist_cwd \n";

			# update file current selected file
			($main::hlist_file, $main::hlist_cwd) = $main::hlist2->info("data", $main::hlist_selection);
			my $ff = $main::hlist_cwd . "/" . $main::hlist_file;

			show_file_prop($ff);
       		}
	);
        $rc_menu -> command
        (
		-label=>"Apply Preview",
		-underline=> 1,
		-command=> sub
		{
			print "Apply Preview: Dir: '$main::hlist_cwd'\n\tfilename:\t'$main::hlist_file'\n\tnew filename:\t'$main::hlist_file_new'\n";
			if(!&fn_rename($main::hlist_file, $main::hlist_file_new) )
			{
				plog(0, "ERROR Apply Preview: \"$main::hlist_file\" cannot preform rename, file allready exists\n");
			}
			else
			{
				# update hlist cells
				$main::hlist2->itemConfigure
				(
					$main::hlist_selection,
					$main::hlist_file_row,
					-text => $main::hlist_file_new
				);

				# update hlist data
				$main::hlist2->entryconfigure
				(
					$main::hlist_selection,
					-data=>[$main::hlist_file_new, $main::hlist_cwd, $main::hlist_file_new]
				);

			}
       		}
	);
        $rc_menu -> command
        (
		-label=>"Manual Rename",
		-underline=> 1,
		-command=> sub
		{
			&manual_edit($main::hlist_file, $main::hlist_cwd);
       		}
	);
        $rc_menu -> command
        (
		-label=>"Delete",
		-underline=> 1,
		-command=> sub
		{
			# update file current selected file
			($main::hlist_file, $main::hlist_cwd) = $main::hlist2->info("data", $main::hlist_selection);
			my $ff = $main::hlist_cwd . "/" . $main::hlist_file;
			show_del_dialog($ff);
       		}
	);


        $main::hlist2->bind('<Any-ButtonPress-3>', \&show_rc_menu);
        $main::hlist2->bind('<Any-ButtonPress-1>',[\&hide_rc_menu, $rc_menu]);
        $main::hlist2->bind('<Any-ButtonPress-2>',[\&hide_rc_menu, $rc_menu]);

	&ls_dir;
}




1;