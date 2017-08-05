package fixname;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;

use Data::Dumper::Concise;
use Cwd;

#--------------------------------------------------------------------------------------------------------------
#
#--------------------------------------------------------------------------------------------------------------

sub fix
{
	return 0 if $main::STOP == 1;

        # -----------------------------------------
	# Vars
        # -----------------------------------------

	my $file 	= shift;
	my $dir		= shift;

	die "fixname::fix : ERROR file is undef.\n"	if ! defined $file;
	die "fixname::fix : ERROR dir is undef.\n"	if ! defined $dir;

        my $newfile		= $file;
        my $tmpfile		= '';

        my @tmp_arr;

        my $tag 		= 0;

        my $tl	       		= 0;	# used for truncating - TODO rename to something obvious
        my $file_ext_length	= 0;
        my $trunc_char_length	= 0;
#         my $l			= 0;
        my $enum_n		= 0;
        my $file_ext		= "";

        my $PRINT		= 0;

        $main::cwd 		= cwd;	# RM - legacy code ???

	my $IS_AUDIO_FILE = 0;
	$IS_AUDIO_FILE = 1 if $file =~ /\.$config::id3_ext_regex$/i;

	if($config::hash{id3_mode}{value} && !-f $file)
	{
		&misc::plog(0, "sub fixname: \"$file\" does not exist");
		&misc::plog(0, "sub fixname: current directory = \"$main::dir\"");
		return;
	}

        # -----------------------------------------
	# make sure file is allowed to be renamed
        # -----------------------------------------
        die "ERROR ig_type is undef\n" if(! defined $main::ig_type);

        my $RENAME 		= 0;

        # file extionsion check
        $RENAME = 1 if(-f $file && ($main::ig_type || $file =~ /\.($config::hash{file_ext_2_proc}{value})$/i));

#	dir check, is a directory, dir mode is enabled
        $RENAME = 1 if($main::proc_dirs && -d $file);

#	processing all file types & dirs
        $RENAME = 1 if($main::proc_dirs && $main::ig_type);

#	didnt match filter
        return if($main::FILTER && &filter::match($file) == 0);

#	rules say file shouldnt be renamed
	return if !$RENAME;

	# recursive, print stuff
	# this code inserts a line between directorys and prints the parent directory.

	if
	(
        	$main::recr &&
                $main::last_recr_dir ne "$main::cwd" &&	# if pwd != last dir
                $main::proc_dirs == 0
        )
	{
		$main::last_recr_dir = $main::cwd;

		&nf_print::p(" ", "<MSG>");
		&nf_print::p($main::cwd, $main::cwd);
	}

	#------------------------------------------------------------------------------
	# Fetch & process audio tags
	# $tag = 1 only if tags are found & id3 mode is enabled

	my %tags_h = ();
	my %tags_h_new = ();

	if($config::hash{id3_mode}{value} && $IS_AUDIO_FILE)
	{
		my $ref = &mp3::get_tags($file);
		my %tags_h = %$ref;
		my %tags_h_new = %tags_h;

		$tag = 1;

		# Do tag stuff now

		my @tags_to_fix = ('artist', 'title', 'album', 'comment');
		for my $k(@tags_to_fix)
		{
			next if $k eq 'track' || $k eq 'year';
			$tags_h_new{$k} = &fn_replace	($tags_h_new{$k});
			$tags_h_new{$k} = &fn_spaces	($tags_h_new{$k});
			$tags_h_new{$k} = &fn_case	($tags_h_new{$k});
			$tags_h_new{$k} = &fn_sp_word	($tags_h_new{$k});
			$tags_h_new{$k} = &fn_case_fl	($tags_h_new{$k});
			$tags_h_new{$k} = &fn_post_clean($tags_h_new{$k});
		}
	}

	# guess id3 tags
	if($config::hash{id3_guess_tag}{value} && $IS_AUDIO_FILE)
        {
		(
			$tags_h_new{artist},
			$tags_h_new{track},
			$tags_h_new{title},
			$tags_h_new{album},
		) = &mp3::guess_tags($newfile);
	}

	#------------------------------------------------------------------------------

	$newfile = &run_fixname_subs($file, $newfile);


	# End of cleanups

	#==========================================================================================================================================
	# check for and apply filename/ id3 changes
	#==========================================================================================================================================

	# set user entered audio tags overrides if any

	if($main::id3_art_set && $IS_AUDIO_FILE)
	{
		$tags_h_new{artist} = $main::id3_art_str;
		$tag	= 1;
	}

	if($main::id3_alb_set && $IS_AUDIO_FILE)
	{
		$tags_h_new{album} = $main::id3_alb_str;
		$tag	= 1;
	}

	if($main::id3_gen_set && $IS_AUDIO_FILE)
	{
		$tags_h_new{genre} = $main::id3_gen_str;
		$tag	= 1;
	}

	if($main::id3_year_set && $IS_AUDIO_FILE)
	{
		$tags_h_new{year} = $main::id3_year_str;
		$tag	= 1;
	}

	if($main::id3_com_set && $IS_AUDIO_FILE)
	{
		$tags_h_new{comment} = $main::id3_com_str;
		$tag	= 1;
	}

	# rm mp3 id3v2 tags
        if($main::id3v2_rm && $_ =~ /\.$config::id3_ext_regex$/i)
	{
        	if(!$main::testmode)
		{
        		&mp3::rm_tags($file);
                }
                else
		{
                	$main::tags_rm++;
                }
                $PRINT++;
        }

	# rm mp3 id3v1 tags
        if($main::id3v1_rm && $main::id3v2_rm && $IS_AUDIO_FILE)
	{
        	$tag = 0;
        }

        # no tags and no fn change, dont rename
	if($tag == 0 && $file eq $newfile)
	{
        	if($PRINT)
		{
                	&nf_print::p($file, $newfile);
                }
		return;
	}

       	if($tag)
	{
       		# fn & tags havent changed
       		my $TAGS_CHANGED = 0;
		if
		(
			$tags_h{artist}		ne $tags_h_new{artist}	||
			$tags_h{title}		ne $tags_h_new{title}	||
			$tags_h{track}		ne $tags_h_new{track}	||
			$tags_h{album}		ne $tags_h_new{album}	||
			$tags_h{genre}		ne $tags_h_new{genre}	||
			$tags_h{comment}	ne $tags_h_new{comment}	||
			$tags_h{year}		ne $tags_h_new{year}
		)
		{
			$TAGS_CHANGED = 1;
		}

		if($file eq $newfile && !$TAGS_CHANGED)	# nothing happened to file or tags
		{
			if($PRINT)
			{
				&nf_print::p($file, $newfile);
			}
        		return;
        	}

		if($TAGS_CHANGED && !$main::testmode)
		{
			&mp3::write_tags($file, \%tags_h_new);
			$main::id3_change++;
		}
	}

	if($file ne $newfile)
	{
		if(!$main::testmode)
		{
			if(!&fn_rename($file, $newfile) )
			{
				&misc::plog(0, "sub fixname: \"$newfile\" cannot preform rename, file allready exists");
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

		\%tags_h,
		\%tags_h_new,
	);
};

#==========================================================================================================================================
#==========================================================================================================================================
#==========================================================================================================================================

# returns 1 if succesfull rename, errors are printed to console

# this code looks messy but it does need to be laid out with the doubled up "if(-e $newfile && !$main::OVERWRITE) "
# bloody fat32 returns positive when we dont want it, ie case correcting

sub fn_rename
{
	if($main::STOP == 1)
	{
		return 0;
	}

	my $file = shift;
	my $newfile = shift;
	my $tmpfile = $newfile."-FSFIX";

	if($config::hash{fat32fix}{value}) 	# work around case insensitive filesystem renaming problems
	{

		if( -e $tmpfile && !$main::OVERWRITE)
		{
			$main::tmpfilefound++;
			$main::tmpfilelist .= "$tmpfile\n";
			&misc::plog(0, "sub fn_rename: \"$tmpfile\" <- tmpfilefound");
			return 0;
		}
		rename $file, $tmpfile;
		if(-e $newfile && !$main::OVERWRITE)
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
		if(-e $newfile && !$main::OVERWRITE)
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
	$main::change++;
	return 1;
}

# this code has been segmented from the sub fixname in order for blockrename to take advantage

sub run_fixname_subs
{
	my $file = shift;
	my $newfile = shift;

	if(!$newfile)
	{
 		$newfile = $file;
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

	return $newfile;
}

# Kill word list function
# removes list of user set words

sub fn_kill_cwords
{
	my $f = shift;
	my $fn = shift;
	my $a = "";

	if(!$fn)
	{
		$fn = $f;
	}
        if($config::hash{kill_cwords}{value})
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
	return $fn;
}

sub fn_replace
{
	my $fn = shift;
	my $f = $fn;

	if($main::replace)
        {
                $fn =~ s/($main::rpwold_escaped)/$main::rpwnew/ig;
        }
	return $fn;
}

sub fn_kill_sp_patterns
{
	my $fn = shift;
	my $f = $fn;

        if($config::hash{kill_sp_patterns}{value})
        {
                for (@main::kill_patterns_arr)
                {
                        $fn =~ s/$_//ig;
                }
        }

	return $fn;
}

sub fn_unscene
{
	my $fn = shift;
	my $f = $fn;

	if($main::unscene)
	{
		$fn =~ s/(S)(\d+)(E)(\d+)/$2.qw(x).$4/ie;
	}

	return $fn;
}

sub fn_scene
{
	my $fn = shift;
	my $f = $fn;

	if($main::scene)
	{
		$fn =~ s/(^|\W)(\d+)(x)(\d+)/$1.qw(S).$2.qw(E).$4/ie;
	}

	return $fn;
}

sub fn_spaces
{
	my $fn = shift;
	my $f = $fn;

        if($config::hash{spaces}{value})
        {
                # underscores to spaces
                $fn =~ s/(\s|_)+/$config::hash{space_character}{value}/g;
	}
	return $fn;
}

sub fn_sp_char
{
	my $fn = shift;
	my $f = $fn;
        if($config::hash{sp_char}{value})
        {
                $fn =~ s/[\~\@\%\{\}\[\]\"\<\>\!\`\'\,\#\(|\)]//g;
        }
	return $fn;
}

# split supposed episode numbers, eg 0103 to 01x03
# trys to avoid obvious years

sub fn_split_dddd
{
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
	return $fn;
}

# case 1st letter
# 1st letter of filename should be uc

sub fn_case_fl
{
	my $fn = shift;
	my $f = $fn;

	if($config::hash{case}{value})
	{
                $fn =~ s/^(\w)/uc($1)/e;
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
	my $f = shift;
	die "sub fn_sp_word, got passed null" if ! defined $f || !$f || $f eq '';

	my $fn = shift;
	my $fn_old = $fn;

        if($config::hash{WORD_SPECIAL_CASING}{value})
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
	return $fn;
}

sub fn_dot2space
{
	my $f = shift;
	my $fn = shift;
        if($config::hash{dot2space}{value})
        {
        	if(-f $f && !-d $f)	# is file and not a directory
        	{
                	$fn =~ s/\./$config::hash{space_character}{value}/g;
	                # put last dot back in front of the ext
        	        # there may be a cleaner way to do this but oh well
                	$fn =~ s/(.*)($config::hash{space_character}{value})(.{3,4}$)/$1\.$3/g;
                }
		else			# not a file treat as a string
		{
			$fn =~ s/\./$config::hash{space_character}{value}/g;
		}
        }
	return $fn;
}

# Pad digits with " - " (must come after pad digits with 0 to catch any new
sub fn_pad_digits
{
	my $fn = shift;
	my $f = $fn;
	if($main::pad_digits)
	{
		# optimize me

		my $tmp = $config::hash{space_character}{value}."-".$config::hash{space_character}{value};
		$fn =~ s/($config::hash{space_character}{value})+(\d\d|\d+x\d+)($config::hash{space_character}{value})+/$tmp.$2.$tmp/ie;
		$fn =~ s/($config::hash{space_character}{value})+(\d\d|\d+x\d+)(\..{3,4}$)/$tmp.$2.$3/ie;
		$fn =~ s/^(\d\d|\d+x\d+)($config::hash{space_character}{value})+/$1.$tmp/ie;
	}
	return $fn;
}

sub fn_pad_digits_w_zero
{
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
	return $fn;
}

sub fn_digits
{
	my $fn = shift;
	my $f = $fn;
	if($main::digits)
	{
		# remove leading digits (Track Nr)
		$fn =~ s/^\d*\s*//;
	}
	return $fn;
}

sub fn_enum
{
	my $f = shift;
	my $fn = shift;
	if($main::enum)
	{
        	my $enum_n = $main::enum_count;

        	if($config::hash{enum_pad}{value} == 1)
        	{
        		$a = "%.$config::hash{enum_pad_zeros}{value}"."d";
        		$enum_n = sprintf($a, $enum_n);
 		}

        	if($config::hash{enum_opt}{value} == 0)
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
        	} elsif($config::hash{enum_opt}{value} == 1)
        	{
			# Insert N at begining of filename
        	        $fn = "$enum_n"."$fn";
		} elsif($config::hash{enum_opt}{value} == 2)
		{
			# Insert N at end of filename but before file ext
			$fn =~ s/(.*)(\..*$)/$1$enum_n$2/g;
		}
                $main::enum_count++;
	}
	return $fn;
}

sub fn_truncate
{
	my $f = shift;
	my $fn = shift;
	my $tl = "";

	my $l = length $fn;
	if($l > $config::hash{'max_fn_length'}{'value'} && $config::hash{'truncate_to'}{'value'} == 0)
	{
		&misc::plog(0, "sub fn_truncate: $fn exceeds maximum filename length.");
		return;
	}
	if($l > $config::hash{'truncate_to'}{'value'} && $main::truncate == 1)
	{
		my $file_ext = $fn;
		$file_ext =~ s/^(.*)(\.)(.{3,4})$/$3/e;
		my $file_ext_length = length $file_ext;	# doesnt include . in length

		# var for adjusted truncate to, gotta take into account file ext length
		$tl = $config::hash{'truncate_to'}{'value'} - ($file_ext_length + 1);	# tl = truncate length

		# adjust tl to allow for added enum digits if enum mode is enabled
		if($main::enum && $config::hash{enum_pad}{value})
		{
			$tl = $tl - $config::hash{enum_pad_zeros}{value};
		}
		elsif($main::enum)
		{
			$tl = $tl - length "$main::enum_count";
		}

		# start truncating

		# from front
		if($config::hash{truncate_style}{value} == 0)
		{
			$fn =~ s/^(.*)(.{$tl})(\..{$file_ext_length})$/$2.$3/e;
		}

		# from end
		elsif($config::hash{truncate_style}{value} == 1)
		{
 			$fn =~ s/^(.{$tl})(.*)(\..{$file_ext_length})$/$1.$3/e;
		}

		# from middle
		elsif($config::hash{truncate_style}{value} == 2)
		{
			$tl = int ($tl - length $config::hash{trunc_char}{value}) / 2;

			$fn =~ s/^(.{$tl})(.*)(.{$tl})(\..{$file_ext_length})$/$1.$config::hash{trunc_char}{value}.$3.$4/e;
		}
	}
	return $fn;
}

sub fn_pre_clean
{
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
	return $fn;
}

sub fn_post_clean
{
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
                $fn =~ s/$config::hash{space_character}{value}+/$config::hash{space_character}{value}/g;

		# change file extension to lower case and remove anyspaces before file ext
                $fn =~ s/^(.*)(\..{3,4})$/$1.lc($2)/e;

                if(-d $f)
                {
                	$fn =~ s/(\s|\+|_|\.|-)+$//;
                }
	}
	return $fn;
}

sub fn_front_a
{
	my $fn = shift;
	my $f = $fn;
        if($main::front_a)
        {
                $fn = $main::faw.$fn;
        }
	return $fn;
}

sub fn_end_a
{
	my $fn = shift;
	my $f = $fn;
        if($main::end_a)
        {
                $fn =~ s/(.*)(\..*$)/$1$main::eaw$2/g;
        }
	return $fn;
}

sub fn_pad_dash
{
	my $fn = shift;
	my $f = $fn;
	if($main::pad_dash == 1)
	{
		$fn =~ s/(\s*|_|\.)(-)(\s*|_|\.)/$config::hash{space_character}{value}."-".$config::hash{space_character}{value}/eg;
	}
	return $fn;
}

sub fn_rm_digits
{
	my $fn = shift;
	my $f = $fn;
        if($main::rm_digits)
        {
        	my $t_s = "";
                $fn =~ s/\d+//g;
        }
	return $fn;
}

sub fn_lc_all
{
	# lowercase all
	my $fn = shift;
	my $f = $fn;
        if($config::hash{lc_all}{value})
	{
                $fn = lc($fn);
        }
	return $fn;
}

sub fn_uc_all
{
	# uppercase all
	my $fn = shift;
	my $f = $fn;
        if($config::hash{uc_all}{value})
	{
                $fn = uc($fn);
        }
	return $fn;
}

sub fn_intr_char
{
	# International Character translation
        # WARNING: This might break really badly on some systems, esp. non-Unix ones...
	# if you see alot of ? in your filenames, you need to add the correct codepage for the filesystem.

	my $fn = shift;
	my $f = $fn;

        if($config::hash{intr_char}{value})
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
	return $fn;
}

sub fn_case
{
	my $fn = shift;
	my $f = $fn;
        if($config::hash{case}{value})
        {
                $fn =~ s/(^| |\.|_|\(|-)([A-Za-z������������������������������])(([A-Za-z������������������������������]|\'|\�|\�|\�)*)/$1.uc($2).lc($3)/eg;
	}
	return $fn;
}


1;