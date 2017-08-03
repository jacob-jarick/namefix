package fixname;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;
use Cwd;

#--------------------------------------------------------------------------------------------------------------
# fixname
#--------------------------------------------------------------------------------------------------------------

sub run_fixname
{
	return 0 if $main::STOP == 1;

	&misc::plog(3, "sub fixname");

        # -----------------------------------------
	# Vars
        # -----------------------------------------

	my $file 	= shift;
        if(!$file) { return; }     # prevent null entrys being processed
	&misc::plog(3, "sub fixname: processing \"$file\"");

        $main::id3_writeme 	= 0;
        my $newfile		= $file;
        my $tmpr 		= 1;
        my @tmp_arr;

        my $tag 		= 0;
        my $art 		= "";
        my $tit			= "";
        my $tra			= "";
        my $alb			= "";
        my $gen			= "";
        my $year		= "";
        my $com			= "";
        my $newart 		= "";
        my $newtit		= "";
        my $newtra		= "";
        my $newalb		= "";
        my $newgen		= "";
        my $newyear		= "";
        my $newcom		= "";

        my $tmp	       		= "";
        my $t_s	       		= "";
        my $tl	       		= 0;
        my $file_ext_length	= 0;
        my $trunc_char_length	= 0;
        my $l	       		= 0;
        my $enum_n		= 0;
        my $file_ext		= "";
        my $tmpfile		= "";

        $main::cwd 		= cwd;	# RM - legacy code ???

	if($main::id3_mode && !-f $file)
	{
		&misc::plog(0, "sub fixname: \"$file\" does not exist");
		&misc::plog(0, "sub fixname: current directory = \"$main::dir\"");
	}

        # -----------------------------------------
	# make sure file is allowed to be renamed
        # -----------------------------------------

        if((!-d $file) && ($main::ig_type || $file =~ /\.($main::file_ext_2_proc)$/i))
	{
		&misc::plog(4, "sub fixname: \"$file\" passed file extionsion check");
                $tmpr = 0;
        }

        if($main::proc_dirs && -d $file)
	{
		&misc::plog(4, "sub fixname: \"$file\" passed dir check, is a directory, dir mode is enabled");
                $tmpr = 0;
        }

        if($main::proc_dirs && $main::ig_type)
	{
		&misc::plog(4, "sub fixname: \"$file\" being passed regardless, we are processing all file types");
                $tmpr = 0;
        }

        if($main::FILTER && &filter::match($file) == 0)
	{
		&misc::plog(4, "sub fixname: \"$file\" didnt match filter");
        	return;
        }
        if($tmpr == 1)
	{
		&misc::plog(4, "sub fixname: rules say file shouldnt be renamed");
        	return;
        }

	# recursive, print stuff
	# this code inserts a line between directorys and prints the parent directory.

	if
	(
        	$main::recr &&
                $main::last_recr_dir ne "$main::cwd" &&	# if pwd != last dir
                $main::proc_dirs == 0
        )
	{
		&misc::plog(4, "sub fixname: Printing dir in gui dirlist");
		$main::last_recr_dir = $main::cwd;

		&nf_print::p(" ", "<MSG>");
		&nf_print::p($main::cwd, $main::cwd);
	}

	# Fetch mp3 tags, if file is a mp3 and id3 mode is enabled
	# $tag will =1 only if tags r found & id3 mode is enabled

	if($main::id3_mode & $file =~ /.*\.mp3$/)
	{
	&misc::plog(4, "sub fixname: getting mp3 tags");
		@tmp_arr = &mp3::get_tags($file);
		if($tmp_arr[0] eq "id3v1")
		{
			$tag = 1;
			$newart 	= $art 		= $tmp_arr[1];
			$newtit 	= $tit 		= $tmp_arr[2];
			$newtra 	= $tra 		= $tmp_arr[3];
			$newalb 	= $alb 		= $tmp_arr[4];
                        $newgen		= $gen	 	= $tmp_arr[5];
                        $newyear 	= $year		= $tmp_arr[6];
			$newcom 	= $com 		= $tmp_arr[7];
		}

		# Do tag stuff now

		$newart = &fn_replace($newart);
		$newtit = &fn_replace($newtit);
		$newalb = &fn_replace($newalb);
		$newcom = &fn_replace($newcom);

		$newart = &fn_spaces($newart);
		$newtit = &fn_spaces($newtit);
		$newalb = &fn_spaces($newalb);
		$newcom = &fn_spaces($newcom);

		$newart = &fn_case($newart);
		$newtit = &fn_case($newtit);
		$newalb = &fn_case($newalb);
		$newcom = &fn_case($newcom);

		$newart = &fn_sp_word($file, $newart);
		$newtit = &fn_sp_word($file, $newtit);
		$newalb = &fn_sp_word($file, $newalb);
		$newcom = &fn_sp_word($file, $newcom);

		$newart = &fn_case_fl($newart);
		$newtit = &fn_case_fl($newtit);
		$newalb = &fn_case_fl($newalb);
		$newcom = &fn_case_fl($newcom);

		$newart = &fn_post_clean($newart);
		$newtit = &fn_post_clean($newtit);
		$newalb = &fn_post_clean($newalb);
		$newcom = &fn_post_clean($newcom);
	}

	$newfile = &run_fixname_subs($file, $newfile);

	# guess id3 tags
	if($main::id3_guess_tag == 1 && $_ =~ /.*\.mp3$/)
        {
		($newart, $newtra, $newtit, $newalb) = &guess_tags($newfile);
	}

	# End of cleanups

	#==========================================================================================================================================
	# check for and apply filename/ id3 changes
	#==========================================================================================================================================

	&misc::plog(4, "sub fixname: set user entered tags if any");

	if($main::id3_art_set && $file =~ /.*\.mp3$/i)
	{
		$newart = $main::id3_art_str;
		$tag	= 1;
	}

	if($main::id3_alb_set && $file =~ /.*\.mp3$/i)
	{
		$newalb = $main::id3_alb_str;
		$tag	= 1;
	}

	if($main::id3_gen_set && $file =~ /.*\.mp3$/i)
	{
		$newgen = $main::id3_gen_str;
		$tag	= 1;
	}

	if($main::id3_year_set && $file =~ /.*\.mp3$/i)
	{
		$newyear = $main::id3_year_str;
		$tag	= 1;
	}

	if($main::id3_com_set && $file =~ /.*\.mp3$/i)
	{
		$newcom = $main::id3_com_str;
		$tag	= 1;
	}

        if($main::id3v1_rm && $file =~ /.*\.mp3$/i)
	{
        	if(!$main::testmode)
		{
        		&rm_tags($file, "id3v1");
                }
                else
		{
                	$main::tags_rm++;
                }
                $tmp = "printme";
        }

	# rm mp3 id3v2 tags
        if($main::id3v2_rm && $_ =~ /.*\.mp3$/i)
	{
        	if(!$main::testmode)
		{
        		&rm_tags($file, "id3v2");
                }
                else
		{
                	$main::tags_rm++;
                }
                $tmp = "printme";
        }

	# rm mp3 id3v1 tags
        if($main::id3v1_rm && $main::id3v2_rm && $file =~ /.*\.mp3$/i)
	{
        	$tag = 0;
        }

	if($tag == 0 && $file eq $newfile)
	{
        	if($tmp eq "printme")
		{
                	&nf_print::p($file, $newfile);
                }
		&misc::plog(3, "sub fixname: no tags and no fn change, dont rename");
		return;
	}

       	if($tag)
	{
       		# fn & tags havent changed

		if
		(
			$main::id3_writeme == 0 &&
			$file eq $newfile &&
			$art eq $newart &&
			$tit eq $newtit &&
			$tra eq $newtra &&
			$alb eq $newalb &&
			$com eq $newcom &&
			$gen eq $newgen &&
			$year eq $newyear
        	)
		{
			if($tmp eq "printme")
			{
				&nf_print::p($file, $newfile);
			}
        		return;
        	}

		if
		(
			$main::id3_writeme == 1 ||
			$art ne $newart ||
			$tit ne $newtit ||
			$tra ne $newtra ||
			$alb ne $newalb ||
			$com ne $newcom ||
			$gen ne $newgen ||
			$year ne $newyear
        	)
		{
			&misc::plog(4, "sub fixname: one or more tags changed, write n bump counter");
        		if(!$main::testmode)
			{
				&write_tags($file, $newart, $newtit, $newtra, $newalb, $newcom, $newgen, $newyear);
			}
			$main::id3_change++;
		}
	}

	if($file ne $newfile)
	{
		if(!$main::testmode)
		{
			if(!&fn_rename($file, $newfile) )
			{
				plog(0, "sub fixname: \"$newfile\" cannot preform rename, file allready exists");
				return 0;
			}
		}
		else
		{
			# increment change for preview count
			$main::change++;
		}
	}

	&nf_print::p
	(
		$file,
		$newfile,

		$art,
		$tit,
		$tra,
		$alb,
		$com,
		$gen,
		$year,

		$newart,
		$newtit,
		$newtra,
		$newalb,
		$newcom,
		$newgen,
		$newyear
	);
};

#==========================================================================================================================================
#==========================================================================================================================================
#==========================================================================================================================================

# returns 1 if succesfull rename, errors are printed to console

# this code looks messy but it does need to be laid out with the doubled up "if(-e $newfile && !$main::overwrite) "
# bloody fat32 returns positive when we dont want it, ie case correcting

sub fn_rename
{
	if($main::STOP == 1)
	{
		return 0;
	}

	&misc::plog(3, "sub fn_rename");
	my $file = shift;
	my $newfile = shift;
	my $tmpfile = $newfile."-FSFIX";

	&misc::plog(4, "sub fn_rename: \"$file\" \"$newfile\"");

	if($main::fat32fix) 	# work around case insensitive filesystem renaming problems
	{

		if( -e $tmpfile && !$main::overwrite)
		{
			$main::tmpfilefound++;
			$main::tmpfilelist .= "$tmpfile\n";
			&misc::plog(0, "sub fn_rename: \"$tmpfile\" <- tmpfilefound");
			return 0;
		}
		rename $file, $tmpfile;
		if(-e $newfile && !$main::overwrite)
		{
			rename $tmpfile, $file;
			&misc::plog(0, "sub fn_rename: \"$newfile\" refusing to rename, file exists");
			return 0;
		}
		else
		{
			rename $tmpfile, $newfile;
			&undo::add("$main::cwd/$file", "$main::cwd/$newfile");
		}
	}
	else
	{
		if(-e $newfile && !$main::overwrite)
		{
			$main::suggestF++;
			&misc::plog(0, "sub fn_rename: \"$newfile\" refusing to rename, file exists");
			return 0;
		}
		else
		{
			rename $file, $newfile;
			&undo::add("$main::cwd/$file", "$main::cwd/$newfile");
		}
	}
	&misc::plog(4, "sub fn_rename: \"$file\" to \"$newfile\" renamed.");
	$main::change++;
	return 1;
}

# this code has been segmented from the sub fixname in order for blockrename to take advantage

sub run_fixname_subs
{
	my $file = shift;
	my $newfile = shift;

	&misc::plog(3, "sub run_fixname_subs:");
	if(!$newfile)
	{
		&misc::plog(4, "sub run_fixname_subs: processing \"$file\"");
	}
	else
	{
		&misc::plog(4, "sub run_fixname_subs: processing \"$file\", \"$newfile\"");
	}

	# ---------------------------------------
	# 1st Run, do before cleanup
	# ---------------------------------------

	$newfile = &fn_scene($newfile);			# Scenify Season & Episode numbers
	$newfile = &fn_unscene($newfile);		# Unscene Season & Episode numbers
	$newfile = &fn_kill_sp_patterns($newfile);	# remove patterns
        $newfile = &fn_kill_cwords($file, $newfile);	# remove list of words
	$newfile = &fn_replace($newfile);		# remove user entered word (also replace if anything is specified)
	$newfile = &fn_spaces($newfile);		# convert underscores to spaces
	$newfile = &fn_pad_dash($newfile);		# pad -
	$newfile = &fn_dot2space($file, $newfile);	# Dots to spaces
	$newfile = &fn_sp_char($newfile);		# remove nasty characters
	$newfile = &fn_rm_digits($newfile);		# remove all digits
	$newfile = &fn_digits($newfile);		# remove digits from front of filename
	$newfile = &fn_split_dddd($newfile);		# split season episode numbers

	$newfile = &fn_pre_clean($newfile);		# Preliminary cleanup (just cleans up after 1st run)

	# ---------------------------------------
	# Main Clean - these routines expect a fairly clean string
	# ---------------------------------------

	$newfile = &fn_intr_char($newfile);		# International Character translation
	$newfile = &fn_case($newfile);			# Apply casing
	$newfile = &fn_pad_digits_w_zero($newfile);	# Pad digits with 0
	$newfile = &fn_pad_digits($newfile);		# Pad NN w - , Pad digits with " - "
        $newfile = &fn_sp_word($file, $newfile); 	# Specific word casing

	$newfile = &fn_post_clean($file, $newfile);	# Post General cleanup

	# ---------------------------------------
	# 2nd runs some routines need to be run before & after cleanup in order to work fully (allows for lazy matching)
	# ---------------------------------------

	$newfile = &fn_kill_sp_patterns($newfile);	# remove patterns
        $newfile = &fn_kill_cwords($file, $newfile);	# remove list of words

	# ---------------------------------------
	# Final cleanup
	# ---------------------------------------
	$newfile = &fn_spaces($newfile);		# spaces

	$newfile = &fn_front_a($newfile);		# Front append
	$newfile = &fn_end_a($newfile);			# End append

	$newfile = &fn_case_fl($newfile);		# UC 1st letter of filename
	$newfile = &fn_lc_all($newfile);		# lowercase all
	$newfile = &fn_uc_all($newfile);		# uppercase all
	$newfile = &fn_truncate($file, $newfile);	# truncate file
	$newfile = &fn_enum($file, $newfile); 		# Enumerate

	if($file eq $newfile)
	{
		&misc::plog(4, "sub run_fixname_subs: no modifications to \"$file\"");
	}
	else
	{
		&misc::plog(4, "sub run_fixname_subs: \"$file\" to \"$newfile\"");
	}
	return $newfile;
}

# Kill word list function
# removes list of user set words

sub fn_kill_cwords
{
	&misc::plog(3, "sub fn_kill_cwords");
	my $f = shift;
	my $fn = shift;
	my $a = "";

	if(!$fn)
	{
		$fn = $f;
	}
        if($main::kill_cwords)
        {
        	if(-d $f)	# if directory process as normal
                {

	                for $a(@main::kill_words_arr_escaped)
                        {
	                        $fn =~ s/(^|-|_|\.|\s+|\,|\+|\(|\[|\-)($a)(\]|\)|-|_|\.|\s+|\,|\+|\-|$)/$1.$3/ig;
	                }
		}
                else		# if its a file, be careful not to remove the extension, hence why we dont match on $
                {
	                for $a(@main::kill_words_arr_escaped)
                        {
	                        $fn =~ s/(^|-|_|\.|\s+|\,|\+|\(|\[|\-)($a)(\]|\)|-|_|\.|\s+|\,|\+|\-)/$1.$3/ig;
	                }
                }
        }

	if($f ne $fn)
	{
		&misc::plog(4, "sub fn_kill_cwords: \$f\" to \"$fn\"");
	}
	return $fn;
}

sub fn_replace
{
	&misc::plog(3, "sub fn_replace ");
	my $fn = shift;
	my $f = $fn;

	if($main::replace)
        {
                $fn =~ s/($main::rpwold_escaped)/$main::rpwnew/ig;
        }
	if($f ne $fn)
	{
		&misc::plog(4, "sub fn_replace: \"$f\" to \"$fn\"");
	}
	return $fn;
}

sub fn_kill_sp_patterns
{
	&misc::plog(3, "sub fn_kill_sp_patterns ");
	my $fn = shift;
	my $f = $fn;

        if($main::kill_sp_patterns)
        {
                for (@main::kill_patterns_arr)
                {
                        $fn =~ s/$_//ig;
                }
        }

	if($f ne $fn)
	{
		&misc::plog(4, "sub fn_kill_sp_patterns: \"$f\" to \"$fn\"");
	}
	return $fn;
}

sub fn_unscene
{
	&misc::plog(3, "sub fn_unscene ");
	my $fn = shift;
	my $f = $fn;

	if($main::unscene)
	{
		$fn =~ s/(S)(\d+)(E)(\d+)/$2.qw(x).$4/ie;
	}

	if($f ne $fn)
	{
		&misc::plog(4, "sub fn_unscene: \"$f\" to \"$fn\"");
	}
	return $fn;
}

sub fn_scene
{
	&misc::plog(3, "sub fn_scene ");
	my $fn = shift;
	my $f = $fn;

	if($main::scene)
	{
		$fn =~ s/(^|\W)(\d+)(x)(\d+)/$1.qw(S).$2.qw(E).$4/ie;
	}

	if($f ne $fn)
	{
		&misc::plog(4, "sub fn_scene: \"$f\" to \"$fn\"");
	}
	return $fn;
}

sub fn_spaces
{
	&misc::plog(3, "sub fn_spaces");
	my $fn = shift;
	my $f = $fn;

        if($main::spaces)
        {
                # underscores to spaces
                $fn =~ s/(\s|_)+/$main::space_character/g;
	}
	if($f ne $fn)
	{
		&misc::plog(4, "sub fn_spaces: \"$f\" to \"$fn\"");
	}
	return $fn;
}

sub fn_sp_char
{
	&misc::plog(3, "sub fn_sp_char");
	my $fn = shift;
	my $f = $fn;
        if($main::sp_char)
        {
                $fn =~ s/[\~\@\%\{\}\[\]\"\<\>\!\`\'\,\#\(|\)]//g;
        }
	if($f ne $fn)
	{
		&misc::plog(4, "sub fn_sp_char: \"$f\" to \"$fn\"");
	}
	return $fn;
}

# split supposed episode numbers, eg 0103 to 01x03
# trys to avoid obvious years

sub fn_split_dddd
{
	&misc::plog(3, "sub fn_split_dddd");
	my $fn = shift;
	my $f = $fn;

        if($main::split_dddd)
	{
        	if($fn =~ /(.*?)(\d{3,4})(.*)/)
                {
	                my @tmp_arr = ($1, $2, $3);
	                if(length $tmp_arr[1] == 3)
                        {
	                        $tmp_arr[1] =~ s/(\d{1})(\d{2})/$1."x".$2/e;
	                        $fn = $tmp_arr[0].$tmp_arr[1].$tmp_arr[2];
	                }
	                elsif(length $tmp_arr[1] == 4)
                        {
                        	if($tmp_arr[1] !~ /^(19|20)(\d+)/)
                                {
	                                $tmp_arr[1] =~ s/(\d{2})(\d{2})/$1."x".$2/e;
	                                $fn = $tmp_arr[0].$tmp_arr[1].$tmp_arr[2];
                                }
	                }

                }
        }
	if($f ne $fn)
	{
		&misc::plog(4, "sub fn_split_dddd: \"$f\" to \"$fn\"");
	}
	return $fn;
}

# case 1st letter
# 1st letter of filename should be uc

sub fn_case_fl
{
	&misc::plog(3, "sub fn_case_fl");
	my $fn = shift;
	my $f = $fn;

	if($main::case)
	{
                $fn =~ s/^(\w)/uc($1)/e;
	}

	if($f ne $fn)
	{
		&misc::plog(4, "sub fn_case_fl: \"$f\" to \"$fn\"");
	}
	return $fn;
}

# --------------------
# fn_sp_word

# this func gets passed filename (when needed)
# reason being is directory and strings are processed normally
# and files are checked for a file extension and handled accordingly
# so we need to check if its a file and not a dir
# easier to send filename each time than a special flag / string I figured

sub fn_sp_word
{
	&misc::plog(3, "sub fn_sp_word");
	my $f = shift;
	if(!$f)
	{
		&misc::plog(0, "sub fn_sp_word, got passed null");
		return;
	}
	my $fn = shift;
	my $fn_old = $fn;

        if($main::WORD_SPECIAL_CASING)
        {
        	my $word = "";
                foreach $word(@main::word_casing_arr)
                {
                	$word =~ s/(\s+|\n+|\r+)+$//;
                	$word = quotemeta $word;
			if(-f $f && !-d $f)	# is file and not a directory
			{
				$fn =~ s/(^|\s+|_|\.|\(|\[)($word)(\s+|_|\.|\)|\]|\..{3,4}$)/$1.$word.$3/egi;
			}
			else			# not a file treat as a string
			{
				$fn =~ s/(^|\s+|_|\.|\(|\[)($word)(\s+|_|\.|\(|\]|$)/$1.$word.$3/egi
			}
                }
        }
	if($f ne $fn)
	{
		&misc::plog(4, "sub fn_sp_word: \"$fn_old\" to \"$fn\"");
	}
	return $fn;
}

sub fn_dot2space
{
	&misc::plog(3, "sub fn_dot2space");
	my $f = shift;
	my $fn = shift;
        if($main::dot2space)
        {
        	if(-f $f && !-d $f)	# is file and not a directory
        	{
                	$fn =~ s/\./$main::space_character/g;
	                # put last dot back in front of the ext
        	        # there may be a cleaner way to do this but oh well
                	$fn =~ s/(.*)($main::space_character)(.{3,4}$)/$1\.$3/g;
                }
		else			# not a file treat as a string
		{
			$fn =~ s/\./$main::space_character/g;
		}
        }
	if($f ne $fn)
	{
		&misc::plog(4, "sub fn_dot2space: \"$f\" to \"$fn\"");
	}
	return $fn;
}

# Pad digits with " - " (must come after pad digits with 0 to catch any new
sub fn_pad_digits
{
	&misc::plog(3, "sub fn_pad_digits");
	my $fn = shift;
	my $f = $fn;
	if($main::pad_digits)
	{
		# optimize me

		my $tmp = $main::space_character."-".$main::space_character;
		$fn =~ s/($main::space_character)+(\d\d|\d+x\d+)($main::space_character)+/$tmp.$2.$tmp/ie;
		$fn =~ s/($main::space_character)+(\d\d|\d+x\d+)(\..{3,4}$)/$tmp.$2.$3/ie;
		$fn =~ s/^(\d\d|\d+x\d+)($main::space_character)+/$1.$tmp/ie;
	}
	if($f ne $fn)
	{
		&misc::plog(4, "sub fn_pad_digits: \"$f\" to \"$fn\"");
	}
	return $fn;
}

sub fn_pad_digits_w_zero
{
	&misc::plog(3, "sub fn_pad_digits_w_zero");
	my $fn = shift;
	my $f = $fn;
	if($main::pad_digits_w_zero)
	{
		# rm extra 0's
		$fn =~ s/(^|\s+|\.|_)(\d{1,2})(x0)(\d{2})(\s+|\.|_|\..{3,4}$)/$1.$2."x".$4.$5/ieg;

		# pad NxN
		$fn =~ s/(^|\s+|\.|_)(\dx)(\d)(\s+|\.|_|\..{3,4}$)/$1."0".$2."0".$3.$4/ie;	# NxN to 0Nx0N
		$fn =~ s/(^|\s+|\.|_)(\d\dx)(\d)(\s+|\.|_|\..{3,4}$)/$1.$2."0".$3.$4/ie;	# NNxN to NNx0N
		$fn =~ s/(^|\s+|\.|_)(\dx)(\d\d)(\s+|\.|_|\..{3,4}$)/$1."0".$2.$3.$4/ie;	# NxNN to 0NxNN

		# clean scene style
		# rm extra 0's
		$fn =~ s/(^s|\s+s|\.s|_s)(\d{1,2})(e0)(\d{2})(\s+|\.|_|\..{3,4}$)/$1.$2."e".$4.$5/ieg;

		$fn =~ s/(^s|\s+s|\.s|_s)(\d)(e)(\d)(\s+|\.|_|\..{3,4}$)/$1."0".$2."0".$3.$4.$5/ie;	# sNeN to S0Ne0N
		$fn =~ s/(^s|\s+s|\.s|_s)(\d\d)(e)(\d)(\s+|\.|_|\..{3,4}$)/$1.$2.$3."0".$4.$5/ie;		# sNNeN to sNNe0N
		$fn =~ s/(^s|\s+s|\.s|_s)(\d)(e)(\d\d)(\s+|\.|_|\..{3,4}$)/$1."0".$2.$3.$4.$5/ie;		# SNeNN to S0NeNN
	}
	if($f ne $fn)
	{
		&misc::plog(4, "sub fn_pad_digits_w_zero: \"$f\" to \"$fn\"");
	}
	return $fn;
}

sub fn_digits
{
	&misc::plog(3, "sub fn_digits");
	my $fn = shift;
	my $f = $fn;
	if($main::digits)
	{
		# remove leading digits (Track Nr)
		$fn =~ s/^\d*\s*//;
	}
	if($f ne $fn)
	{
		&misc::plog(4, "sub fn_digits: \"$f\" to \"$fn\"");
	}
	return $fn;
}

sub fn_enum
{
	&misc::plog(3, "sub fn_enum");
	my $f = shift;
	my $fn = shift;
	if($main::enum)
	{
        	my $enum_n = $main::enum_count;

        	if($main::enum_pad == 1)
        	{
        		$a = "%.$main::enum_pad_zeros"."d";
        		$enum_n = sprintf($a, $enum_n);
 		}

        	if($main::enum_opt == 0)
        	{
        		if(-d $f)
        		{
        			$fn = $enum_n;
        		}
        		else
        		{
        			# numbers and file ext only
        			$fn =~ s/^.*\././;
        			$fn = "$enum_n"."$fn";
        		}
        	} elsif($main::enum_opt == 1)
        	{
			# Insert N at begining of filename
        	        $fn = "$enum_n"."$fn";
		} elsif($main::enum_opt == 2)
		{
			# Insert N at end of filename but before file ext
			$fn =~ s/(.*)(\..*$)/$1$enum_n$2/g;
		}
                $main::enum_count++;
	}
	if($f ne $fn)
	{
		&misc::plog(4, "sub fn_enum: \"$f\" to \"$fn\"");
	}
	return $fn;
}

sub fn_truncate
{
	&misc::plog(3, "sub fn_truncate");
	my $f = shift;
	my $fn = shift;
	my $tl = "";

	my $l = length $fn;
	if($l > $main::max_fn_length && $main::truncate == 0)
	{
		&misc::plog(0, "sub fn_truncate: $fn exceeds maximum filename length.");
		return;
	}
	if($l > $main::truncate_to && $main::truncate == 1)
	{
		my $file_ext = $fn;
		$file_ext =~ s/^(.*)(\.)(.{3,4})$/$3/e;
		my $file_ext_length = length $file_ext;	# doesnt include . in length

		# var for adjusted truncate to, gotta take into account file ext length
		$tl = $main::truncate_to - ($file_ext_length + 1);	# tl = truncate length

		# adjust tl to allow for added enum digits if enum mode is enabled
		if($main::enum && $main::enum_pad)
		{
			$tl = $tl - $main::enum_pad_zeros
		}
		elsif($main::enum)
		{
			$tl = $tl - length "$main::enum_count";
		}

		# start truncating

		# from front
		if($main::truncate_style == 0)
		{
			$fn =~ s/^(.*)(.{$tl})(\..{$file_ext_length})$/$2.$3/e;
		}

		# from end
		elsif($main::truncate_style == 1)
		{
 			$fn =~ s/^(.{$tl})(.*)(\..{$file_ext_length})$/$1.$3/e;
		}

		# from middle
		elsif($main::truncate_style == 2)
		{
			$tl = int ($tl - length $main::trunc_char) / 2;

			$fn =~ s/^(.{$tl})(.*)(.{$tl})(\..{$file_ext_length})$/$1.$main::trunc_char.$3.$4/e;
		}
	}
	if($f ne $fn)
	{
		&misc::plog(4, "sub fn_truncate: \"$f\" to \"$fn\"");
	}
	return $fn;
}

sub fn_pre_clean
{
	&misc::plog(3, "sub fn_pre_clean");
	my $fn = shift;
	my $f = $fn;
        if($main::cleanup == 1)
        {
                # "fix Artist - - track" type filenames that can pop up when stripping words
                $fn =~ s/-(\s|_|\.)+-/-/g;

                # rm trailing characters
                $fn =~ s/(\s|_|\.|-)+(\..{3,4})$/$2/e;

                # remove leading chars
                $fn =~ s/^(\s|_|\.|-)+//;

                # I hate mpeg or jpeg as extensions personally :P
                $fn =~ s/\.mpeg$/\.mpg/i;
                $fn =~ s/\.jpeg$/\.jpg/i;
        }
	if($f ne $fn)
	{
		&misc::plog(4, "sub fn_pre_clean: \"$f\" to \"$fn\"");
	}
	return $fn;
}

sub fn_post_clean
{
	&misc::plog(3, "sub fn_post_clean");
	my $f = shift;
	my $fn = shift;

	if(!$fn)
	{
		$fn = $f;
	}

        if($main::cleanup == 1)
	{
                # remove childless brackets () [] {}
                $fn =~ s/(\(|\[|\{)(\s|_|\.|\+|-)*(\)|\]|\})//g;

                # remove doubled up -'s
                $fn =~ s/-(\s|_|\.)+-|--/-/g;

                # rm trailing characters
                $fn =~ s/(\s|\+|_|\.|-)+(\..{3,4})$/$2/;

                # rm leading characters
                $fn =~ s/^(\s|\+|_|\.|-)+//;

                # rm extra whitespaces
                $fn =~ s/\s+/ /g;
                $fn =~ s/$main::space_character+/$main::space_character/g;

		# change file extension to lower case and remove anyspaces before file ext
                $fn =~ s/^(.*)(\..{3,4})$/$1.lc($2)/e;

                if(-d $f)
                {
                	$fn =~ s/(\s|\+|_|\.|-)+$//;
                }
	}
	if($f ne $fn)
	{
		&misc::plog(4, "sub fn_post_clean: \"$f\" to \"$fn\"");
	}
	return $fn;
}

sub fn_front_a
{
	&misc::plog(3, "sub fn_front_a");
	my $fn = shift;
	my $f = $fn;
        if($main::front_a)
        {
                $fn = $main::faw.$fn;
        }
	if($f ne $fn)
	{
		&misc::plog(4, "sub fn_front_a: \"$f\" to \"$fn\"");
	}
	return $fn;
}

sub fn_end_a
{
	&misc::plog(3, "sub fn_end_a");
	my $fn = shift;
	my $f = $fn;
        if($main::end_a)
        {
                $fn =~ s/(.*)(\..*$)/$1$main::eaw$2/g;
        }
	if($f ne $fn)
	{
		&misc::plog(4, "sub fn_end_a:  \"$f\" to \"$fn\"");
	}
	return $fn;
}

sub fn_pad_dash
{
	&misc::plog(3, "sub fn_pad_dash");
	my $fn = shift;
	my $f = $fn;
	if($main::pad_dash == 1)
	{
		$fn =~ s/(\s*|_|\.)(-)(\s*|_|\.)/$main::space_character."-".$main::space_character/eg;
	}
	if($f ne $fn)
	{
		&misc::plog(4, "sub fn_pad_dash: \"$f\" to \"$fn\"");
	}
	return $fn;
}

sub fn_rm_digits
{
	&misc::plog(3, "sub fn_rm_digits");
	my $fn = shift;
	my $f = $fn;
        if($main::rm_digits)
        {
        	my $t_s = "";
                $fn =~ s/\d+//g;
        }
	if($f ne $fn)
	{
		&misc::plog(4, "sub fn_rm_digits: \"$f\" to \"$fn\"");
	}
	return $fn;
}

sub fn_lc_all
{
	&misc::plog(3, "sub fn_lc_all");
	# lowercase all
	my $fn = shift;
	my $f = $fn;
        if($main::lc_all)
	{
                $fn = lc($fn);
        }
	if($f ne $fn)
	{
		&misc::plog(4, "sub fn_lc_all: \"$f\" to \"$fn\"");
	}
	return $fn;
}

sub fn_uc_all
{
	&misc::plog(3, "sub fn_uc_all");
	# uppercase all
	my $fn = shift;
	my $f = $fn;
        if($main::uc_all)
	{
                $fn = uc($fn);
        }
	if($f ne $fn)
	{
		&misc::plog(4, "sub fn_uc_all: \"$f\" to \"$fn\"");
	}
	return $fn;
}

sub fn_intr_char
{
	&misc::plog(3, "sub fn_intr_char");
	# International Character translation
        # WARNING: This might break really badly on some systems, esp. non-Unix ones...
	# if you see alot of ? in your filenames, you need to add the correct codepage for the filesystem.

	my $fn = shift;
	my $f = $fn;

        if($main::intr_char)
        {
                $fn =~ s/�/Aa/g;
                $fn =~ s/�/Ae/g;
                $fn =~ s/�/A/g;
                $fn =~ s/�/ae/g;

		$fn =~ s/�/ss/g;

                $fn =~ s/�/E/g;

                $fn =~ s/�/I/g;

		$fn =~ s/�/N/g;

		$fn =~ s/�/O/g;
                $fn =~ s/�/Oe/g;
                $fn =~ s/�/Oo/g;

                $fn =~ s/�/Ue/g;
		$fn =~ s/�/U/g;

                $fn =~ s/�/a/g;
                $fn =~ s/�/a/g;	# mems 1st addition to int support
                $fn =~ s/�/a/g;
                $fn =~ s/�/aa/g;
                $fn =~ s/�/ae/g;
                $fn =~ s/�/ae/g;

		$fn =~ s/�/c/g;

                $fn =~ s/�/e/g;
		$fn =~ s/�/e/g;

                $fn =~ s/�/i/g;

		$fn =~ s/�/n/g;

                $fn =~ s/�/oo/g;
                $fn =~ s/�/oe/g;
		$fn =~ s/�/o/g;
		$fn =~ s/�/o/g;

		$fn =~ s/�/u/g;
                $fn =~ s/�/ue/g;

		$fn =~ s/�//g;
		$fn =~ s/�//g;
		$fn =~ s/�//g;
        }
	if($f ne $fn)
	{
		&misc::plog(4, "sub fn_intr_char: \"$f\" to \"$fn\"");
	}
	return $fn;
}

sub fn_case
{
	&misc::plog(3, "sub fn_case");
	my $fn = shift;
	my $f = $fn;
        if($main::case)
        {
                $fn =~ s/(^| |\.|_|\(|-)([A-Za-z������������������������������])(([A-Za-z������������������������������]|\'|\�|\�|\�)*)/$1.uc($2).lc($3)/eg;
	}
	if($f ne $fn)
	{
		&misc::plog(4, "sub fn_case: \"$f\" to \"$fn\"");
	}
	return $fn;
}


1;