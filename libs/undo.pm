# undo routines
package undo;
require Exporter;
@ISA = qw(Exporter);

use warnings;
use strict;

sub clear
{
 	# clear undo arrays, atm we only have 1 level of undo
	&misc::plog(3, "sub undo::clear: wiping undo history");
	@main::undo_cur		= ();
	@main::undo_pre		= ();

	&misc::save_file($main::undo_cur_file, "");
	&misc::save_file($main::undo_pre_file, "");
	&misc::save_file($main::undo_dir_file, $main::dir);
	$main::undo_dir = $main::dir;
}

sub add
{
	my $f1 = shift;
	my $f2 = shift;

	push @main::undo_pre, $f1;
	push @main::undo_cur, $f2;

	&misc::file_append($main::undo_pre_file, "$f1\n");
	&misc::file_append($main::undo_cur_file, "$f2\n");
}

sub undo_rename
{
	# for some reason when CLI called undo full paths were causing havoc
	# I read up on perls rename and it doesnt have the most relaible behaviour
	# especicially when cross platform coding.
	# undo_rename needs to be able to handle for paths for recursive undos
	#
	# Work around:
	# grabs directory from filename
	# changes to directory
	# chops FQ filename to filename.

	&misc::plog(3, "sub undo_rename");
	&misc::plog(1, "Preforming Undo");
	my $c = 0;
	my $pre = "";
	my $dir = "";

	for my $cur(@main::undo_cur)
	{
		$pre = $main::undo_pre[$c];
		$cur =~ m/^(.*\/)(.*?)$/;
		$dir = $1;
		$cur = $2;
		chdir $dir;
		$pre =~ m/^(.*\/)(.*?)$/;
		$pre = $2;

  		if(!-f "$cur")
 		{
 			&misc::plog(0, "sub undo_rename: \"$cur\" current file does not exist");
 		}
 		if(-f "$pre")
 		{
 			&misc::plog(0, "sub undo_rename: \"$pre\" previous filename to revert undo to allready exists");
 		}

		&misc::plog(4, "sub undo_rename: rename $cur $pre");
		rename $cur, $pre;
		&nf_print::p($cur, $pre);
		$c++;
	}
	chdir $main::dir;
	return 1;
}



1;