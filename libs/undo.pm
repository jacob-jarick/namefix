# undo routines
package undo;
require Exporter;
@ISA = qw(Exporter);

use warnings;
use strict;
use Cwd;

sub clear
{
 	# clear undo arrays, atm we only have 1 level of undo
	@config::undo_cur		= ();
	@config::undo_pre		= ();

	&misc::null_file($globals::undo_cur_file);
	&misc::null_file($globals::undo_pre_file);
	&misc::save_file($globals::undo_dir_file, cwd);
	$globals::undo_dir = $globals::dir = cwd;
}

sub add
{
	my $f1 = shift;
	my $f2 = shift;

	push @config::undo_pre, $f1;
	push @config::undo_cur, $f2;

	&misc::file_append($globals::undo_pre_file, "$f1\n");
	&misc::file_append($globals::undo_cur_file, "$f2\n");
}

sub undo_rename
{
	# for some reason when CLI called undo full paths were causing havoc
	# I read up on Perl's rename and it doesn't have the most reliable behaviour
	# especicially when cross platform coding.
	# undo_rename needs to be able to handle for paths for recursive undos
	#
	# Work around:
	# grabs directory from filename
	# changes to directory
	# chops FQ filename to filename.

	&misc::plog(2, "Performing Undo");
	my $c = 0;
	my $pre = '';

	if(&state::busy)
	{
		&misc::plog(0, "undo_rename: aborting, namefix is busy");
		return;
	}
	
	&state::set('run');
	&dir_hlist::draw_list;	# blank main hlist

	for my $c (0 .. $#config::undo_cur)
	{
		if(&state::check('stop'))
		{
			&misc::plog(0, "UNDO stopped by user");
			last; # do not return, let cleanup happen below
		}

		my $cur = $globals::undo_cur[$c];
		my $pre = $globals::undo_pre[$c];

		$cur =~ s/^(.*\/)(.*?)$/$2/;
		my $dir = $1;
		$pre =~ s/^(.*\/)(.*?)$/$2/;

  		if(!-f $cur)
 		{
 			&misc::plog(0, "undo_rename: aborted, '$cur' current file does not exist");
 			&state::set('idle');
 			return;
 		}
 		if
 		(
			!($config::hash{fat32fix}{value} && lc $pre eq lc $cur) &&	# allow fat32fix to do its magic
			-f $pre
 		)
 		{
 			&misc::plog(0, "undo_rename:  aborted, cannot rename '$cur' to '$pre', file exists");
 			next;
 		}

		&misc::plog(2, "undo_rename: rename '$cur' -> '$pre'");
		&fixname::fn_rename($cur, $pre);
		&nf_print::p($cur, $pre);
	}

	if(&state::check('stop'))
	{
		&misc::plog(1, "UNDO stopped by user");
	}

	chdir $globals::dir;
	&state::set('idle');
	return 1;
}



1;
