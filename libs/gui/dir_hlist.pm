package dir_hlist;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;
use Cwd;
use Data::Dumper::Concise;

our $hlist;
our $rc_menu;

our $target_dir = '';
our %info = ();

our $counter = 0;

our $hlist_selection = 0;

#--------------------------------------------------------------------------------------------------------------
# info hash manager
#--------------------------------------------------------------------------------------------------------------

sub info_add
{
	my $index	= shift;
	my $path	= shift;	# full path to actual file
	my $file	= shift;	# old / current filename
	my $newfile	= shift;	# new / undef filename

	&main::quit("info_add: \$index is undef")			if ! defined $index;
	&main::quit("info_add: \$index '$index' is not an int")		if $index !~ /^\d+$/;
	&main::quit("info_add: \$path is undef")			if ! defined $path;
	&main::quit("info_add: \$path '$path' is not a file or dir")	if !-f $path && !-d $path;

	$info{$index}{path}		= &misc::get_file_path($path);
	$info{$index}{filename}		= $file;
	$info{$index}{parent}		= &misc::get_file_parent_dir($path);
	$info{$index}{new_filename}	= $newfile if defined $newfile;
}

#--------------------------------------------------------------------------------------------------------------
# clear list
#--------------------------------------------------------------------------------------------------------------

sub hlist_clear
{
	$counter = 0;
	&draw_list if !defined $hlist;
	$hlist->delete("all");
	%info = ();

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

	$hlist_selection = $s;
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
		&misc::plog(3, "cd: '$wd'");
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
	if(!$config::update_delay || !$config::LISTING)
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
		'HList',
		-scrollbars		=> 'osoe',
		-header			=> 1,
		-columns		=> $columns,
		-selectbackground	=> 'Cyan',
		-browsecmd => sub
		{
			# when user clicks on an entry update global variables
			$hlist_selection	= shift;
# 			print "BROWSE: \n" . Dumper($info{$hlist_selection}) . "\n";
               	},
		-command=> sub
		{
                	# user has double clicked
 			$target_dir	= $info{$hlist_selection}{parent};
			$target_dir	= $info{$hlist_selection}{path} if -d $info{$hlist_selection}{path} && $config::hlist_file ne '..';

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

	# ----------------------------------------------------------------------------
	# Right Click Menu

        $rc_menu = $hlist->Menu(-tearoff=>0);
        $rc_menu -> command
        (
		-label=>'Properties',
		-underline=> 1,
		-command=> sub
		{
			my $path = $info{$hlist_selection}{path};
			print "Properties path='$path'\n";

			&dialog::show_file_prop($path);
       		}
	);
        $rc_menu -> command
        (
		-label=>'Apply Preview',
		-underline=> 1,
		-command=> sub
		{
			&misc::plog (2, "Apply Preview: filename:\t'$info{$hlist_selection}{filename}', new filename:\t'$info{$hlist_selection}{new_filename}'");

			my $file_old = $info{$hlist_selection}{path};
			my $file_new = $file_old;
			$file_new = $info{$hlist_selection}{new_filename} if defined $info{$hlist_selection}{new_filename};

			if(!&fixname::fn_rename( $file_old, $file_new) )
			{
				&misc::plog(0, "ERROR Apply Preview: '$file_old' cannot preform rename, new file '$file_new' allready exists\n");
			}
			else
			{
				# update hlist cells
				$hlist->itemConfigure
				(
					$hlist_selection,
					$config::hlist_file_row,
					-text => $file_new
				);
				# TODO update info hash
				$info{$hlist_selection}{filename} = $info{$hlist_selection}{new_filename};
			}
       		}
	);
        $rc_menu -> command
        (
		-label=>'Manual Rename',
		-underline=> 1,
		-command=> sub { &manual::edit( $info{$hlist_selection}{path} ); }
	);
        $rc_menu -> command
        (
		-label=>'Delete',
		-underline=> 1,
		-command=> sub
		{ &dialog::show_del_dialog( $info{$hlist_selection}{path} ); }
	);


        $hlist->bind('<Any-ButtonPress-3>', \&show_rc_menu);
        $hlist->bind('<Any-ButtonPress-1>',[\&hide_rc_menu, $rc_menu]);
        $hlist->bind('<Any-ButtonPress-2>',[\&hide_rc_menu, $rc_menu]);
}


1;
