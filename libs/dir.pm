# =============================================================================================================
# directory listing related functions
# =============================================================================================================

use strict;
use warnings;

#--------------------------------------------------------------------------------------------------------------
# List Directory
#--------------------------------------------------------------------------------------------------------------

sub ls_dir 
{
	&plog(3, "sub ls_dir");
	&prep_globals;
	&hlist_clear;
	
	if($main::LISTING)
	{
		&plog(0, "sub ls_dir: Allready preforming a list, aborting new list attempt");
		return 0;
	}

	$main::STOP = 0;
	$main::LISTING = 1;
	chdir $main::dir;	# shift directory, not just list ;)
	$main::dir = cwd(); 

        my @file_list = ();
        my @dirlist = &dir_filtered($main::dir);

	&ls_dir_print("..");

        if($main::recr) 
        {
		&plog(4, "sub ls_dir: recursive mode");
		@main::find_arr = ();
	        find(\&find_fix, "$main::dir");
		&ls_dir_find_fix;
                $main::LISTING = 0;
                $main::FIRST_DIR_LISTED = 0;
	        return;
        }
        else 
        {
		&plog(4, "sub ls_dir: non recursive mode");
        	for(@dirlist) 
        	{
			if($_ eq "..")
			{
				next;
			}
                	if(-d $_) 
                	{
	                	&ls_dir_print($_);	# print directorys 1st
                        }
                        else 
                        {
                        	push @file_list, $_;	# push files to array
                        }
                }
                for(@file_list) 
                {
                	if($main::STOP == 1)
			{
				return 0;
			}
                	&ls_dir_print($_);		# then print the file array after all dirs have been printed
                }
                $main::LISTING = 0;
                $main::FIRST_DIR_LISTED = 0;
                return;
        }
}

#--------------------------------------------------------------------------------------------------------------
# ls_dir_print
#--------------------------------------------------------------------------------------------------------------

sub ls_dir_find_fix
{
	# this sub should recieve an array of files from find_fix

	my @list = @main::find_arr;
	my $d = cwd();
	my $file = "";
	my $dir = "";

	&plog(3, "sub ls_dir_find_fix:");

	for $file(@main::find_arr)
	{
		&plog(4, "sub ls_dir_find_fix: list line \"$file\"");
		$file =~ m/^(.*)\/(.*?)$/;
		$dir = $1;
		$file = $2;
		&plog(4, "sub ls_dir_find_fix: dir = \"$dir\"");
		&plog(4, "sub ls_dir_find_fix: file = \"$file\"");

		chdir $dir;	# change to dir containing file
		&ls_dir_print($file);
		chdir $d;	# change back to dir sub started in
	}
	&plog(3, "sub find_fix_process: done");
	return 1;
}


# this function is only called from ls_dir & ls_dir_find_fix

sub ls_dir_print
{
	my $file = shift;

	if($main::STOP == 1)
	{
		&plog(4, "sub ls_dir_print: \$main::STOP = \"$main::STOP\" - not printing");
		return 0;
	}
	&plog(3, "sub ls_dir_print: \"$file\"");
	
	$main::hlist_cwd = cwd;
	
        my $tag = "";
        my $art = "";
        my $tit = "";
        my $tra = "";
        my $alb = "";
        my $com = "";
        my $gen = "";
        my $year = "";
	my $d = cwd();

        if(!$file || $file eq "" || $file eq ".")
        {
		&plog(4, "sub ls_dir_print: \$file = \"$file\" not printing");
        	return;
        }

	if($file eq "..")
	{
		&nf_print("..", "..");
		return;
	}

	# recursive padding

	# when doing recursive, pad new dir with a blank line
	# since when doing recursive we step through each directory while listing, 
	# we simply print cwd for a full dir path.

	if(-d $file && $main::recr) 	
	{
		&nf_print(" ", "<MSG>");
		&nf_print("$d/$file", "$d/$file");
		return;
	}

	# if is mp3 & id3_mode enabled then grab id3 tags
	if($file =~ /.*\.mp3$/i && $main::id3_mode == 1) 
	{
		&plog(4, "sub ls_dir_print: if is mp3 & id3_mode enabled then grab id3 tags");
		($tag, $art, $tit, $tra, $alb, $gen, $year, $com) = &get_tags($file);

       		if ($tag eq "id3v1") 
       		{
			&plog(4, "sub ls_dir_print: got id3 tags, printing");
			&nf_print($file, $file, $art, $tit, $tra, $alb, $com, $gen, $year);
			return;
		}
	}

	&plog(4, "sub ls_dir_print: doesnt meet any special conditions, just print it");
	&nf_print($file, $file);
}

#--------------------------------------------------------------------------------------------------------------
# Dir Dialog
#--------------------------------------------------------------------------------------------------------------

sub dir_dialog 
{
	&plog(3, "sub dir_dialog");
	my $old_dir = $main::dir;

	my $dd_dir = $main::mw->chooseDirectory
	(
		-initialdir=>$main::dir,
		-title=>"Choose a directory"
	);

	if($dd_dir) 
	{
		$main::dir = $dd_dir;
                chdir $main::dir;
		&ls_dir;
	}
	else 
	{
		$main::dir = $old_dir;
	}
}

#--------------------------------------------------------------------------------------------------------------
# fn_readdir, also removes . and .. from listing which nf needs
#--------------------------------------------------------------------------------------------------------------

sub fn_readdir
{
	&plog(3, "sub fn_readdir");
	my $dir = shift;
	my @dirlist = ();
	my @dirlist_clean = ();
	my @d = ();

	opendir(DIR, "$dir") or die "can't open dir \"$dir\": $!";
	@dirlist = CORE::readdir(DIR);
	closedir DIR;

	# -- make sure we dont have . and .. in array --
	for my $item(@dirlist)
	{
		if($item eq "." || $item eq "..")
		{
			next;
		}
		push @dirlist_clean, $item;
	}

	@dirlist = &ci_sort(@dirlist);  # sort array
	return @dirlist;
}

sub dir_filtered
{
	my $dir = shift;
	my @d = ();
	my @dirlist = &fn_readdir($dir);

	&plog(3, "sub dir_filtered \"$dir\"");	

	for my $i(@dirlist)
	{
		if(-d $i && (!$main::LISTING && !$main::proc_dirs))	# ta tibbsy for help
 		{
			&plog(4, "sub dir_filtered: $i is dir, didnt pass");
 			next;
 		}
		if($main::FILTER)
		{
			if(&match_filter($i) == 1)	# apply listing filter
			{	
				&plog(4, "sub dir_filtered: $i passed");
				push @d, $i;
				next;
			}
			else
			{
				&plog(4, "sub dir_filtered: $i didnt pass");
				next;
			}
		}
		else
		{
			push @d, $i;
			next;
		}
	}
	return @d;
}

1;
