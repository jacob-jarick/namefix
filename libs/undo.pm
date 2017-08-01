# undo routines

use warnings;
use strict;

sub clear_undo
{
 	# clear undo arrays, atm we only have 1 level of undo
	&plog(3, "sub clear_undo: wiping undo history");
	@main::undo_cur		= ();
	@main::undo_pre		= ();

	&save_file($main::undo_cur_file, "");
	&save_file($main::undo_pre_file, "");
	&save_file($main::undo_dir_file, $main::dir);
	$main::undo_dir = $main::dir;
}

sub undo_add
{
	my $f1 = shift;
	my $f2 = shift;

	push @main::undo_pre, $f1;
	push @main::undo_cur, $f2;

	&file_append($main::undo_pre_file, "$f1\n");
	&file_append($main::undo_cur_file, "$f2\n");
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

	&plog(3, "sub undo_rename");
	&plog(1, "Preforming Undo");
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
 			&plog(0, "sub undo_rename: \"$cur\" current file does not exist");
 		}
 		if(-f "$pre")
 		{
 			&plog(0, "sub undo_rename: \"$pre\" previous filename to revert undo to allready exists");
 		}
 
		&plog(4, "sub undo_rename: rename $cur $pre");
		rename $cur, $pre;
		&nf_print($cur, $pre);
		$c++;
	}
	chdir $main::dir;
	return 1;
}



1;