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

	&misc::null_file($config::undo_cur_file);
	&misc::null_file($config::undo_pre_file);
	&misc::save_file($config::undo_dir_file, cwd);
	$config::undo_dir = $config::dir = cwd;
}

sub add
{
	my $f1 = shift;
	my $f2 = shift;

	push @config::undo_pre, $f1;
	push @config::undo_cur, $f2;

	&misc::file_append($config::undo_pre_file, "$f1\n");
	&misc::file_append($config::undo_cur_file, "$f2\n");
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

	&misc::plog(1, "Preforming Undo");
	my $c = 0;
	my $pre = "";
	my $dir = "";

	for my $cur(@config::undo_cur)
	{
		$pre = $config::undo_pre[$c];
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

		&misc::plog(1, "sub undo_rename: rename $cur $pre");
		rename $cur, $pre;
		&nf_print::p($cur, $pre);
		$c++;
	}
	chdir $config::dir;
	return 1;
}



1;