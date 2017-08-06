package dir_hlist;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;
use Cwd;

our $hlist;
our $rc_menu;

#--------------------------------------------------------------------------------------------------------------
# clear list
#--------------------------------------------------------------------------------------------------------------

sub hlist_clear
{
	$main::hl_counter = 0;
	&draw_list if !defined $hlist;
	$hlist->delete("all");

	return 1;
}

#--------------------------------------------------------------------------------------------------------------
# hlist right click menu
#--------------------------------------------------------------------------------------------------------------

sub show_rc_menu
{
	my ($x, $y)	= $main::mw->pointerxy;
	my $s		= $hlist->nearest($y - $hlist->rooty);

	$hlist->selectionClear();
	$hlist->selectionSet($s);

	$main::hlist_selection = $s;
	$rc_menu->post($x,$y);
}

sub hide_rc_menu
{
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

        if(-d $path)
	{
        	$main::dir = $path;
                if(chdir $main::dir)
		{
			$main::dir = cwd();
	        	&dir::ls_dir;
	        	&misc::plog(3, "sub hlist_cd: \"$file\"");
	        	return;
		}
		$main::dir = $old;
        }
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
	$hlist->destroy if defined $hlist;

	my $count	= 0;
	my $columns	= 0;
	my @id3_headers = ('Artist', 'Track', 'Title', 'Album', 'Genre', 'Year', 'Comment');

	my $ic = scalar(@id3_headers);	# count of id3 headers

	# with id3 tags: icon, filename
	if($config::hash{id3_mode}{value})
	{
		$columns	= 9;			# listing
		$columns	= 18 if  $main::RUN;	# preview / rename
	}
	else
	{
		$columns	= 2;			# listing
		$columns	= 4 if  $main::RUN;	# preview / rename
	}

	$hlist = $main::frm_right2 -> Scrolled
        (
		"HList",
		-scrollbars		=> 'osoe',
		-header			=> 1,
		-columns		=> $columns,
		-selectbackground	=> 'Cyan',
		-browsecmd => sub
		{
                	# when user clicks on an entry update global variables
               		$main::hlist_selection = shift;
               		($main::hlist_file, $main::hlist_cwd, $main::hlist_file_new) = $hlist->info("data", $main::hlist_selection);
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

	# listing/ rename / preview - add '<VALUE>' column headers
	$hlist->header('create', $count++, -text =>'Icon');
	$hlist->header('create', $count++, -text =>'Filename');      # for norm & id3 mode


	if($config::hash{id3_mode}{value})
	{
		for my $header(@id3_headers)
		{
			$hlist->header('create', $count++, -text => $header);
		}
	}

	# rename / preview - add 'New <VALUE>' column headers
	if($main::RUN)
	{
		$hlist->header('create', $count++, -text => '#');
		$hlist->header('create', $count++, -text => 'New Filename');
		if($config::hash{id3_mode}{value} == 1)
		{
			for my $header(@id3_headers)
			{
# 				print "$count = New $header\n";
				$hlist->header('create', $count++, -text => "New $header");

			}
		}
	}
	&main::quit("draw_list \$count $count > \$columns $columns\n") if($count > $columns);
# 	print "draw_list = \$count = $count, \$columns = $columns\n";

	# ----------------------------------------------------------------------------
	# Right Click Menu

        $rc_menu = $hlist->Menu(-tearoff=>0);
        $rc_menu -> command
        (
		-label=>"Properties",
		-underline=> 1,
		-command=> sub
		{
			print "Stub Properties $main::hlist_file, $main::hlist_cwd \n";

			# update file current selected file
			($main::hlist_file, $main::hlist_cwd) = $hlist->info("data", $main::hlist_selection);
			my $ff = $main::hlist_cwd . "/" . $main::hlist_file;

			&show_file_prop($ff);
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
				&misc::plog(0, "ERROR Apply Preview: \"$main::hlist_file\" cannot preform rename, file allready exists\n");
			}
			else
			{
				# update hlist cells
				$hlist->itemConfigure
				(
					$main::hlist_selection,
					$main::hlist_file_row,
					-text => $main::hlist_file_new
				);

				# update hlist data
				$hlist->entryconfigure
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
			&manual::edit($main::hlist_file, $main::hlist_cwd);
       		}
	);
        $rc_menu -> command
        (
		-label=>"Delete",
		-underline=> 1,
		-command=> sub
		{
			# update file current selected file
			($main::hlist_file, $main::hlist_cwd) = $hlist->info("data", $main::hlist_selection);
			my $ff = $main::hlist_cwd . "/" . $main::hlist_file;
			&dialog::show_del_dialog($ff);
       		}
	);


        $hlist->bind('<Any-ButtonPress-3>', \&show_rc_menu);
        $hlist->bind('<Any-ButtonPress-1>',[\&hide_rc_menu, $rc_menu]);
        $hlist->bind('<Any-ButtonPress-2>',[\&hide_rc_menu, $rc_menu]);

	&dir::ls_dir;
}


1;