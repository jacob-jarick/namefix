package dir_hlist;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;
use Cwd;

our $hlist;
our $rc_menu;

our $target_dir = '';

#--------------------------------------------------------------------------------------------------------------
# clear list
#--------------------------------------------------------------------------------------------------------------

sub hlist_clear
{
	$config::hl_counter = 0;
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

	$config::hlist_selection = $s;
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
	if(&config::busy)
	{
		&misc::plog(1, "dir::hlist_cd: cannot CD, busy\n");
		return;
	}

	my $wd = shift;

	if(-d $wd && chdir $wd)
	{
		$config::dir = cwd();
		&dir::ls_dir;
		&misc::plog(3, "sub hlist_cd: \"$wd\"");
		return;
	}
        return;
}

#--------------------------------------------------------------------------------------------------------------
# hlist_update
#--------------------------------------------------------------------------------------------------------------
# called from various subs that need updates, update is delayed n times for speedups.

sub fn_update_delay
{
	$config::update_delay--;
	if($config::update_delay == 0 || $config::LISTING == 0)
	{
		$main::mw->update();
		$config::update_delay = $config::delay;
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
		$columns	= 18 if  $config::RUN;	# preview / rename
	}
	else
	{
		$columns	= 2;			# listing
		$columns	= 4 if  $config::RUN;	# preview / rename
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
			$config::hlist_selection = shift;
			($config::hlist_file, $target_dir, $config::hlist_file_new) = $hlist->info('data', $config::hlist_selection);

			$target_dir = "$target_dir/$config::hlist_file" if -d "$target_dir/$config::hlist_file" && $config::hlist_file ne '..';
			print "BROWSE: hlist_file = '$config::hlist_file', target_dir = '$target_dir', hlist_file_new = '$config::hlist_file_new'\n";
               	},
		-command=> sub
		{
                	# user has double clicked
			&hlist_cd($target_dir);
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
	if($config::RUN)
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
			print "Properties hlist_file='$config::hlist_file'\n";

			# update file current selected file
			($config::hlist_file, my $tmp_dir) = $hlist->info("data", $config::hlist_selection);

			&dialog::show_file_prop($config::hlist_file);
       		}
	);
        $rc_menu -> command
        (
		-label=>"Apply Preview",
		-underline=> 1,
		-command=> sub
		{
			print "Apply Preview: Dir: '$config::hlist_cwd'\n\tfilename:\t'$config::hlist_file'\n\tnew filename:\t'$config::hlist_file_new'\n";
			if(!&fixname::fn_rename($config::hlist_file, $config::hlist_file_new) )
			{
				&misc::plog(0, "ERROR Apply Preview: \"$config::hlist_file\" cannot preform rename, file allready exists\n");
			}
			else
			{
				# update hlist cells
				$hlist->itemConfigure
				(
					$config::hlist_selection,
					$config::hlist_file_row,
					-text => $config::hlist_file_new
				);

				# update hlist data
				$hlist->entryconfigure
				(
					$config::hlist_selection,
					-data=>[$config::hlist_file_new, $config::hlist_cwd, $config::hlist_file_new]
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
			&manual::edit($config::hlist_file, $config::hlist_cwd);
       		}
	);
        $rc_menu -> command
        (
		-label=>"Delete",
		-underline=> 1,
		-command=> sub
		{
			# update file current selected file
			($config::hlist_file, $config::hlist_cwd) = $hlist->info("data", $config::hlist_selection);
			my $ff = $config::hlist_cwd . "/" . $config::hlist_file;
			&dialog::show_del_dialog($ff);
       		}
	);


        $hlist->bind('<Any-ButtonPress-3>', \&show_rc_menu);
        $hlist->bind('<Any-ButtonPress-1>',[\&hide_rc_menu, $rc_menu]);
        $hlist->bind('<Any-ButtonPress-2>',[\&hide_rc_menu, $rc_menu]);

# 	&dir::ls_dir;
}


1;
