package fixname;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;

use Data::Dumper::Concise;
use Cwd;
use Carp;
use jpegexif;

our $last_dir = '';
our $dir = '';

#--------------------------------------------------------------------------------------------------------------
# vars
#--------------------------------------------------------------------------------------------------------------

our $enum_count = 0;

sub fix
{
	return 0 if $config::STOP == 1;

    # -----------------------------------------
	# Vars
    # -----------------------------------------

	my $file 	= shift;
	my $path	= '';

	&main::quit ("fixname::fix : ERROR file is undef")		        	if ! defined $file;
	&main::quit ("fixname::fix : ERROR file eq ''")			        	if $file eq '';
	&main::quit ("fixname::fix : ERROR file '$file' isn't dir/file")	if !-d $file && !-f $file;

	($dir, $file, $path) =  &misc::get_file_info($file);
	chdir $dir;

    my $IS_AUDIO_FILE	    = 0;
    my $tag 		        = 0;
    my $file_ext_length	    = 0;
    my $trunc_char_length	= 0;

    my $newfile		        = $file;
    my $file_ext		    = '';
    my $tmpfile		        = '';

	$IS_AUDIO_FILE = 1 if $file =~ /\.$config::id3_ext_regex$/i;

	if($config::hash{id3_mode}{value} && !-f $file)
	{
		&misc::plog(0, "sub fixname: \"$dir/$file\" does not exist");
		&misc::plog(0, "sub fixname: current directory = \"$config::dir\"");
		return;
	}

    # -----------------------------------------
	# make sure file is allowed to be renamed
    # -----------------------------------------

    &main::quit("ERROR IGNORE_FILE_TYPE is undef\n") if !defined $config::hash{ignore_file_type}{value};

    my $RENAME = 0;

    # file extionsion check
    $RENAME = 1 if -f $file && ($config::hash{ignore_file_type}{value} || $file =~ /\.($config::hash{file_ext_2_proc}{value})$/i);

	# dir check, is a directory, dir mode is enabled
    $RENAME = 1 if $config::hash{proc_dirs}{value} && -d $file;

	# processing all file types & dirs
    $RENAME = 1 if $config::hash{proc_dirs}{value} && $config::hash{ignore_file_type}{value};

	# didnt match filter
    return if $config::hash{filter}{value} && !&filter::match($file);

	# rules say file shouldn't be renamed
	return if !$RENAME;

	# recursive, print stuff
	# this code inserts a line between directorys and prints the parent directory.

	if
	(
        $config::hash{recursive}{value} &&
        $last_dir ne $dir &&
        !$config::hash{proc_dirs}{value}
    )
	{
		$last_dir = $dir;

		if ($config::CLI) 
		{
			print "\n=== Processing Directory: $dir ===\n";
		}
		else 
		{
			&nf_print::p(' ', '<BLANK>');
			&nf_print::p($dir);
		}
	}

	#------------------------------------------------------------------------------
	# EXIF data processing

	# CLI only as its not really needed in gui mode
	# currently it just prints and returns
	# printing is probably ugly

	if($config::CLI && $config::hash{exif_show}{value} && -f $file && $file =~ /\.(jpg|jpeg)$/i)
	{
		my $exif_tags_ref = &jpegexif::list_exif_tags($file);

		if(defined $exif_tags_ref && ref($exif_tags_ref) eq 'HASH')
		{
			print "\n=== EXIF Data for $file ===\n";
			# loop through tags and print them
			for my $tag (sort keys %$exif_tags_ref)
			{
				print "\t$tag: $exif_tags_ref->{$tag}\n";
			}
			print "=== End EXIF Data ===\n\n";
		}
		else
		{
			print "No EXIF data found for $file\n";
		}
	}

	#------------------------------------------------------------------------------
	# Fetch & process audio tags
	# $tag = 1 only if tags are found & id3 mode is enabled

	my %tags_h	    = ();
	my %tags_h_new	= ();

	if($config::hash{id3_mode}{value} && $IS_AUDIO_FILE)
	{
		my $ref		= &mp3::get_tags($path);
		%tags_h		= %$ref;
		%tags_h_new	= %tags_h;
		$tag		= 1;

		my @tags_to_fix = ('artist', 'title', 'album', 'comment');
		for my $k(@tags_to_fix)
		{
			&main::quit("ERROR processing audio file $file - $k is undef") if ! defined $tags_h_new{$k};
			$tags_h_new{$k} = &fn_pre_clean	(0, $tags_h_new{$k});
			$tags_h_new{$k} = &fn_replace	(0, $tags_h_new{$k});
			$tags_h_new{$k} = &fn_spaces	(0, $tags_h_new{$k});
			$tags_h_new{$k} = &fn_case	    (0, $tags_h_new{$k});
			$tags_h_new{$k} = &fn_sp_word	(0, $file, $tags_h_new{$k});
			$tags_h_new{$k} = &fn_case_fl	(0, $tags_h_new{$k});
			$tags_h_new{$k} = &fn_post_clean(0, $tags_h_new{$k});
		}
	}

	#------------------------------------------------------------------------------

	$newfile = run_fixname_subs($file, $newfile);

	# End of cleanups

	#==========================================================================================================================================
	# check for and apply filename/ id3 changes
	#==========================================================================================================================================

	# set user entered audio tags overrides if any

	if($config::hash{audio_set_artist}{value} && $IS_AUDIO_FILE)
	{
		$tags_h_new{artist} = $config::id3_art_str;
		$tag	= 1;
	}

	if($config::hash{audio_set_album}{value} && $IS_AUDIO_FILE)
	{
		$tags_h_new{album} = $config::id3_alb_str;
		$tag	= 1;
	}

	if($config::hash{audio_set_genre}{value} && $IS_AUDIO_FILE)
	{
		$tags_h_new{genre} = $config::id3_gen_str;
		$tag	= 1;
	}

	if($config::hash{audio_set_year}{value} && $IS_AUDIO_FILE)
	{
		$tags_h_new{year} = $config::id3_year_str;
		$tag	= 1;
	}

	if($config::hash{audio_set_comment}{value} && $IS_AUDIO_FILE)
	{
		$tags_h_new{comment} = $config::id3_com_str;
		$tag	= 1;
	}

	# rm mp3 id3v2 tags
    if($IS_AUDIO_FILE && $config::hash{rm_audio_tags}{value})
	{
        if(!$config::PREVIEW)
		{
            &mp3::rm_tags($file);
        }
        else
		{
            $config::tags_rm++;
        }
        $tag = 1;
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

    # no tags and no fn change, don't rename
	return if !$tag && $file eq $newfile;

    if($tag)
	{
        # fn & tags haven't changed
        my $TAGS_CHANGED = 0;
		
		# Check and log individual tag changes
		if(defined $tags_h{artist} && $tags_h{artist} ne $tags_h_new{artist})
		{
			&misc::plog(3, "'$file' ID3 artist: '$tags_h{artist}' -> '$tags_h_new{artist}'");
			$TAGS_CHANGED = 1;
		}
		if(defined $tags_h{title} && $tags_h{title} ne $tags_h_new{title})
		{
			&misc::plog(3, "'$file' ID3 title: '$tags_h{title}' -> '$tags_h_new{title}'");
			$TAGS_CHANGED = 1;
		}
		if(defined $tags_h{track} && $tags_h{track} ne $tags_h_new{track})
		{
			&misc::plog(3, "'$file' ID3 track: '$tags_h{track}' -> '$tags_h_new{track}'");
			$TAGS_CHANGED = 1;
		}
		if(defined $tags_h{album} && $tags_h{album} ne $tags_h_new{album})
		{
			&misc::plog(3, "'$file' ID3 album: '$tags_h{album}' -> '$tags_h_new{album}'");
			$TAGS_CHANGED = 1;
		}
		if(defined $tags_h{genre} && $tags_h{genre} ne $tags_h_new{genre})
		{
			&misc::plog(3, "'$file' ID3 genre: '$tags_h{genre}' -> '$tags_h_new{genre}'");
			$TAGS_CHANGED = 1;
		}
		if(defined $tags_h{comment} && $tags_h{comment} ne $tags_h_new{comment})
		{
			&misc::plog(3, "'$file' ID3 comment: '$tags_h{comment}' -> '$tags_h_new{comment}'");
			$TAGS_CHANGED = 1;
		}
		if(defined $tags_h{year} && $tags_h{year} ne $tags_h_new{year})
		{
			&misc::plog(3, "'$file' ID3 year: '$tags_h{year}' -> '$tags_h_new{year}'");
			$TAGS_CHANGED = 1;
		}

		if($file eq $newfile && !$TAGS_CHANGED)	# nothing happened to file or tags
		{
            return;
        }

		$config::id3_change++ if $TAGS_CHANGED;

		if($TAGS_CHANGED)
		{	
			&misc::plog(3, "'$path' update ID3 tags");	
			if(!$config::PREVIEW)
			{
				&mp3::write_tags("$path", \%tags_h_new);
			}
			&misc::plog(2, "'$path' ID3 tags updated");
		}
	}

	if($file ne $newfile)
	{
		if(!$config::PREVIEW)
		{
			if(!&fn_rename($file, $newfile) )
			{
				&misc::plog(0, "fixname: '$newfile' cannot perform rename, file already exists");
				return 0;
			}
		}
		else
		{
			$config::change++; # increment change for preview count
		}
	}

	if ($config::CLI) 
	{
		# CLI output: simple before -> after format
		if ($file ne $newfile) 
		{
			print "'$file' -> '$newfile'\n";
		}
		elsif ($config::hash{debug}{value} >= 2)
		{
			print "'$file' (no change)\n";
		}
	}
	else 
	{
		&nf_print::p
		(
			$file,
			$newfile,

			\%tags_h,
			\%tags_h_new,
		);
	}
};

#==========================================================================================================================================

# returns 1 if successful rename, errors are printed to console

# this code looks messy but it does need to be laid out with the doubled up "if(-e $newfile && !$config::hash{overwrite}{value}) "
# bloody fat32 returns positive when we don't want it, ie case correcting

sub fn_rename
{
	return 0 if $config::STOP;

	my $file	= shift;
	my $newfile	= shift;

	&main::quit("fn_rename \$file is undef\n")		if ! defined $file;
	&main::quit("fn_rename \$file eq ''\n")			if $file eq '';

    &main::quit("fn_rename \$newfile is undef\n")	if ! defined $newfile;
	&main::quit("fn_rename \$newfile eq ''\n")		if $newfile eq '';

	my $file_name = &misc::get_file_name($file);
	&misc::plog(3, "rename '$file_name' to '$newfile'");

	my $dir		= &misc::get_file_parent_dir($file);
	$newfile	= "$dir/$newfile";
	my $tmpfile = $newfile.'-FSFIX';

	if($config::hash{fat32fix}{value}) 	# work around case insensitive filesystem renaming problems
	{
		if( -e $tmpfile && !$config::hash{overwrite}{value})
		{
			$config::FOUND_TMP++;
			$config::tmpfilelist .= "$tmpfile\n";
			&misc::plog(0, "fn_rename: \"$tmpfile\" <- FOUND_TMP");
			return 0;
		}
		rename $file, $tmpfile;
		if(-e $newfile && !$config::hash{overwrite}{value})
		{
			rename $tmpfile, $file;
			&misc::plog(0, "fn_rename: \"$newfile\" refusing to rename, file exists");
			return 0;
		}
		else
		{
			rename $tmpfile, $newfile;
			&undo::add($file, $newfile);
		}
	}
	else
	{
		if(-e $newfile && !$config::hash{overwrite}{value})
		{
			$config::SUGGEST_FSFIX++;
			&misc::plog(0, "fn_rename: '$newfile' refusing to rename, file exists");
			return 0;
		}
		rename $file, $newfile;
		&undo::add($file, "$dir/$newfile");
	}
	$config::change++;
	return 1;
}

# this code has been segmented from the sub fixname in order for blockrename to take advantage

sub run_fixname_subs
{
	my $file	= shift;
	my $newfile	= shift;

	&main::quit("run_fixname_subs \$file is undef\n")		        if ! defined $file;
	&main::quit("run_fixname_subs \$file eq ''\n")			        if $file eq '';
	&main::quit("run_fixname_subs \$file isn't a dir or file\n")	if !-f $file && !-d $file;

	$newfile = $file if !$newfile;

	# ---------------------------------------
	# 1st Run, do before cleanup
	# ---------------------------------------

    # Scenify Season & Episode numbers
	my $temp = $newfile;
	$newfile = &fn_scene($newfile);				
	&misc::plog(3, "fn_scene: '$temp' -> '$newfile'") if $temp ne $newfile;
	
    # Unscene Season & Episode numbers
	$temp = $newfile;
	$newfile = &fn_unscene($newfile);				
	&misc::plog(3, "fn_unscene: '$temp' -> '$newfile'") if $temp ne $newfile;
	
    # remove patterns
	$temp = $newfile;
	$newfile = &fn_kill_sp_patterns($newfile);				
	&misc::plog(3, "fn_kill_sp_patterns: '$temp' -> '$newfile'") if $temp ne $newfile;
	
    # remove list of words
	$temp = $newfile;
    $newfile = &fn_kill_cwords($file, $newfile);	
	&misc::plog(3, "fn_kill_cwords: '$temp' -> '$newfile'") if $temp ne $newfile;
	
    # remove user entered word (also replace if anything is specified)
	$temp = $newfile;
	$newfile = &fn_replace(1, $newfile);				
	&misc::plog(3, "fn_replace: '$temp' -> '$newfile'") if $temp ne $newfile;
	
    # convert underscores to spaces
	$temp = $newfile;
	$newfile = &fn_spaces(1, $newfile);				
	&misc::plog(3, "fn_spaces: '$temp' -> '$newfile'") if $temp ne $newfile;
	
    # pad -
	$temp = $newfile;
	$newfile = &fn_pad_dash($newfile);				
	&misc::plog(3, "fn_pad_dash: '$temp' -> '$newfile'") if $temp ne $newfile;
	
    # pad N to NN
	$temp = $newfile;
	$newfile = &fn_pad_N_to_NN($newfile);				
	&misc::plog(3, "fn_pad_N_to_NN: '$temp' -> '$newfile'") if $temp ne $newfile;

    # Dots to spaces
	$temp = $newfile;
	$newfile = &fn_dot2space(1, $file, $newfile);	
	&misc::plog(3, "fn_dot2space: '$temp' -> '$newfile'") if $temp ne $newfile;
	
    # remove nasty characters
	$temp = $newfile;
	$newfile = &fn_sp_char($newfile);				
	&misc::plog(3, "fn_sp_char: '$temp' -> '$newfile'") if $temp ne $newfile;
	
    # remove all digits
	$temp = $newfile;
	$newfile = &fn_rm_digits($newfile);				
	&misc::plog(3, "fn_rm_digits: '$temp' -> '$newfile'") if $temp ne $newfile;
	
    # remove digits from front of filename
	$temp = $newfile;
	$newfile = &fn_digits($newfile);				
	&misc::plog(3, "fn_digits: '$temp' -> '$newfile'") if $temp ne $newfile;
	
    # split season episode numbers
	$temp = $newfile;
	$newfile = &fn_split_dddd($newfile);				
	&misc::plog(3, "fn_split_dddd: '$temp' -> '$newfile'") if $temp ne $newfile;
	
    # Preliminary cleanup (just cleans up after 1st run)
	$temp = $newfile;
	$newfile = &fn_pre_clean(1, $file, $newfile);	
	&misc::plog(3, "fn_pre_clean: '$temp' -> '$newfile'") if $temp ne $newfile;

	# ---------------------------------------
	# Main Clean - these routines expect a fairly clean string
	# ---------------------------------------

    # International Character translation
	$temp = $newfile;
	$newfile = &fn_intr_char(1, $newfile);	
	&misc::plog(3, "fn_intr_char: '$temp' -> '$newfile'") if $temp ne $newfile;
	
    # Apply casing
	$temp = $newfile;
	$newfile = &fn_case(1, $newfile);	
	&misc::plog(3, "fn_case: '$temp' -> '$newfile'") if $temp ne $newfile;
	
    # Pad digits with 0
	$temp = $newfile;
	$newfile = &fn_pad_digits_w_zero($newfile);	
	&misc::plog(3, "fn_pad_digits_w_zero: '$temp' -> '$newfile'") if $temp ne $newfile;
	
    # Pad NN w - , Pad digits with " - "
	$temp = $newfile;
	$newfile = &fn_pad_digits($newfile);	
	&misc::plog(3, "fn_pad_digits: '$temp' -> '$newfile'") if $temp ne $newfile;
	
    # Specific word casing
	$temp = $newfile;
    $newfile = &fn_sp_word(1, $file, $newfile); 	
	&misc::plog(3, "fn_sp_word: '$temp' -> '$newfile'") if $temp ne $newfile;

    # Post General cleanup
	$temp = $newfile;
	$newfile = &fn_post_clean(1, $file, $newfile);	
	&misc::plog(3, "fn_post_clean: '$temp' -> '$newfile'") if $temp ne $newfile;

	# ---------------------------------------
	# 2nd runs some routines need to be run before & after cleanup in order to work fully (allows for lazy matching)
	# ---------------------------------------

    # remove patterns
	$temp = $newfile;
	$newfile = &fn_kill_sp_patterns($newfile);          
	&misc::plog(3, "fn_kill_sp_patterns(2nd): '$temp' -> '$newfile'") if $temp ne $newfile;
	
    # remove list of words
	$temp = $newfile;
	$newfile = &fn_kill_cwords($file, $newfile);  
	&misc::plog(3, "fn_kill_cwords(2nd): '$temp' -> '$newfile'") if $temp ne $newfile;

	# ---------------------------------------
	# Final cleanup
	# ---------------------------------------

    # Spaces
	$temp = $newfile;
	$newfile = &fn_spaces(1, $newfile);				
	&misc::plog(3, "fn_spaces(2nd): '$temp' -> '$newfile'") if $temp ne $newfile;

    # Prepend string to front of filename
	$temp = $newfile;
	$newfile = &fn_front_a($newfile);				
	&misc::plog(3, "fn_front_a: '$temp' -> '$newfile'") if $temp ne $newfile;
	
    # Append string to end of filename before the extension
	$temp = $newfile;
	$newfile = &fn_end_a($newfile);				
	&misc::plog(3, "fn_end_a: '$temp' -> '$newfile'") if $temp ne $newfile;

    # Uppercase 1st letter of filename
	$temp = $newfile;
	$newfile = &fn_case_fl(1, $newfile);				
	&misc::plog(3, "fn_case_fl: '$temp' -> '$newfile'") if $temp ne $newfile;
	
    # lowercase all
	$temp = $newfile;
	$newfile = &fn_lc_all($newfile);				
	&misc::plog(3, "fn_lc_all: '$temp' -> '$newfile'") if $temp ne $newfile;
	
    # uppercase all
	$temp = $newfile;
	$newfile = &fn_uc_all($newfile);				
	&misc::plog(3, "fn_uc_all: '$temp' -> '$newfile'") if $temp ne $newfile;
	
    # truncate file
	$temp = $newfile;
	$newfile = &fn_truncate($file, $newfile);	
	&misc::plog(3, "fn_truncate: '$temp' -> '$newfile'") if $temp ne $newfile;
	
    # Enumerate
	$temp = $newfile;
	$newfile = &fn_enum($file, $newfile); 	
	&misc::plog(3, "fn_enum: '$temp' -> '$newfile'") if $temp ne $newfile;

    # log change if any
    &misc::plog(2, "'$file' -> '$newfile'") if $file ne $newfile;

	return $newfile;
}

# Kill word list function
# removes list of user set words

sub fn_kill_cwords
{
	my $file		= shift;
	my $file_new	= shift;

	&main::quit("fn_kill_cwords \$file is undef\n")	if ! defined $file;
	&main::quit("fn_kill_cwords \$file eq ''\n")	if $file eq '';

	$file_new = $file if !defined $file_new || $file_new eq '';

	if($config::hash{kill_cwords}{value})
	{
		if(-d $file)	# if directory process as normal
		{
			for my $a(@config::kill_words_arr)
			{
				$a = quotemeta $a;
				$file_new =~ s/(^|-|_|\.|\s+|\,|\+|\(|\[|\-)($a)(\]|\)|-|_|\.|\s+|\,|\+|\-|$)/$1$3/ig;
			}
		}
		else		# if its a file, be careful not to remove the extension, hence why we don't match on $
		{
			for my $a(@config::kill_words_arr)
			{
				$a = quotemeta $a;
				$file_new =~ s/(^|-|_|\.|\s+|\,|\+|\(|\[|\-)($a)(\]|\)|-|_|\.|\s+|\,|\+|\-)/$1$3/ig;
			}
		}
	}
	return $file_new;
}

sub fn_replace
{
	my $FILE		= shift;
	my $file_new	= shift;

	&main::quit("fn_replace \$file_new is undef\n")	if ! defined $file_new;
	&main::quit("fn_replace \$file_new eq ''\n")	if $FILE && $file_new eq '';

	return $file_new if !$config::hash{replace}{value};

	my $rm = $config::ins_str_old;
	if(!$config::hash{remove_regex}{value})
	{
		$rm = quotemeta $config::ins_str_old;
	}

	$file_new =~ s/($rm)/$config::ins_str/ig;

	return $file_new;
}

sub fn_kill_sp_patterns
{
	my $file_new = shift;
	&main::quit("fn_kill_sp_patterns \$file_new is undef\n")	if ! defined $file_new;
	&main::quit("fn_kill_sp_patterns \$file_new eq ''\n")		if $file_new eq '';

	return $file_new if !$config::hash{kill_sp_patterns}{value};

	for my $pattern (@config::kill_patterns_arr)
	{
		$file_new =~ s/$pattern//ig;
	}

	return $file_new;
}

sub fn_unscene
{
	my $file_new = shift;

	&main::quit("fn_unscene \$file_new is undef\n")	if ! defined $file_new;
	&main::quit("fn_unscene \$file_new eq ''\n")	if $file_new eq '';

	$file_new =~ s/(S)(\d+)(E)(\d+)/$2.qw(x).$4/ie 	if($config::hash{unscene}{value});

	return $file_new;
}

sub fn_scene
{
	my $file_new = shift;
	&main::quit("fn_scene \$file_new is undef\n")	if ! defined $file_new;
	&main::quit("fn_scene \$file_new eq ''\n")		if $file_new eq '';

	return $file_new if $config::hash{scene}{value};

	$file_new =~ s/(^|\W)(\d+)(x)(\d+)/$1.qw(S).$2.qw(E).$4/ie;

	return $file_new;
}

# underscores to spaces
sub fn_spaces
{
	my $FILE		= shift;
	my $file_new	= shift;

	&main::quit("fn_spaces \$file_new is undef\n")	if ! defined $file_new;
	&main::quit("fn_spaces \$file_new eq ''\n") 	if $FILE && $file_new eq '';

	return $file_new if !$config::hash{spaces}{value};

	$file_new =~ s/(\s|_)+/$config::hash{space_character}{value}/g;

	return $file_new;
}

sub fn_sp_char
{
	my $file_new = shift;
	&main::quit("fn_sp_char \$file_new is undef\n")	if ! defined $file_new;
	&main::quit("fn_sp_char \$file_new eq ''\n")	if $file_new eq '';

	return $file_new if !$config::hash{sp_char}{value};

	$file_new =~ s/[\~\@\%\{\}\[\]\"\<\>\!\`\'\,\#\(|\)]//g;

	return $file_new;
}

# split supposed episode numbers, eg 0103 to 01x03
# trys to avoid obvious years

sub fn_split_dddd
{
	my $file_new = shift;

	&main::quit("fn_split_dddd \$file_new is undef\n")	if ! defined $file_new;
	&main::quit("fn_split_dddd \$file_new eq ''\n")		if $file_new eq '';

        return $file_new if !$config::hash{split_dddd}{value};
	if($file_new =~ /(.*?)(\d{3,4})(.*)/)
	{
		my @tmp_arr = ($1, $2, $3);
		if(length $tmp_arr[1] == 3)
		{
			$tmp_arr[1] =~ s/(\d{1})(\d{2})/$1."x".$2/e;
			$file_new = $tmp_arr[0].$tmp_arr[1].$tmp_arr[2];
		}
		elsif(length $tmp_arr[1] == 4)
		{
			if($tmp_arr[1] !~ /^(19|20)(\d+)/)
			{
				$tmp_arr[1] =~ s/(\d{2})(\d{2})/$1."x".$2/e;
				$file_new = $tmp_arr[0].$tmp_arr[1].$tmp_arr[2];
			}
		}
	}
	return $file_new;
}

# case 1st letter
# 1st letter of filename should be uc

sub fn_case_fl
{
	my $FILE		= shift;
	my $file_new	= shift;

	&main::quit("fn_case_fl: \$file_new is undef\n")	if !defined $file_new;
	&main::quit("fn_case_fl: \$file_new eq ''\n")		if $FILE && $file_new eq '';

	return $file_new if !$config::hash{case}{value};
	$file_new =~ s/^(\w)/uc($1)/e;
	return $file_new;
}

# --------------------
# fn_sp_word

# this func gets passed filename (when needed)
# because the file extensions need special handling IF $f is a file

sub fn_sp_word
{
	my $FILE = shift;
	my $file = shift;

	&main::quit("fn_sp_word \$file is undef\n")		if ! defined $file;
	&main::quit("fn_sp_word \$file eq ''\n")		if $FILE && $file eq '';

	my $file_new = shift;
	&main::quit("fn_sp_word \$file_new is undef\n")	if ! defined $file_new;
	&main::quit("fn_sp_word \$file_new eq ''\n")	if $FILE && $file_new eq '';

	return $file_new if !$config::hash{word_special_casing}{value};
	foreach my $word(@config::word_casing_arr)
	{
		my $w = quotemeta $word;
		if(-f $file)	# is file and not a directory
		{
			$file_new =~ s/(^|\s+|_|\.|\(|\[)($w)(\s+|_|\.|\)|\]|\..{3,4}$)/$1.$w.$3/egi;
			next;
		}
		# not a file treat as a string
		$file_new =~ s/(^|\s+|_|\.|\(|\[)($w)(\s+|_|\.|\(|\]|$)/$1.$w.$3/egi
	}
	return $file_new;
}

sub fn_dot2space
{
	my $FILE        = shift;
	my $file        = shift;
	my $file_new    = shift;

	&main::quit("fn_dot2space \$FILE value '$FILE' is invalid\n")	if $FILE != 0 && $FILE != 1;
	&main::quit("fn_dot2space \$file is undef\n")					if ! defined $file;
	&main::quit("fn_dot2space \$file eq ''\n")						if $FILE && $file eq '';

	return $file_new if !$config::hash{dot2space}{value};

	if($FILE && $file_new =~ m/^(.*)\.(.*?)$/g)	# is file and not a directory
	{
		my $name	= $1;
		my $ext		= $2;
		$name		=~ s/\./$config::hash{space_character}{value}/g;
		$file_new	= "$name.$ext";

# 		&misc::plog(2, "sub fn_dot2space: \$ext = '$ext'\n");
	}
	else
	{
		# not a file treat as a string
		$file_new =~ s/\./$config::hash{space_character}{value}/g;
	}
	 	# &misc::plog(2, "sub fn_dot2space: \$file_new 2 '$file_new'\n");
        return $file_new;
}

# Pad digits with " - " (must come after pad digits with 0 to catch any new
sub fn_pad_digits
{
	my $file_new = shift;
	&main::quit("fn_pad_digits \$file_new is undef\n")	if ! defined $file_new;
	&main::quit("fn_pad_digits \$file_new eq ''\n")		if $file_new eq '';

	return $file_new if !$config::hash{pad_digits}{value};

	# TODO: optimize me
	my $tmp = $config::hash{space_character}{value}."-".$config::hash{space_character}{value};

	$file_new =~ s/($config::hash{space_character}{value})+(\d\d|\d+x\d+)($config::hash{space_character}{value})+/$tmp.$2.$tmp/ie;
	$file_new =~ s/($config::hash{space_character}{value})+(\d\d|\d+x\d+)(\..{3,4}$)/$tmp.$2.$3/ie;
	$file_new =~ s/^(\d\d|\d+x\d+)($config::hash{space_character}{value})+/$1.$tmp/ie;

	return $file_new;
}

sub fn_pad_digits_w_zero
{
	my $file_new = shift;
	&main::quit("fn_pad_digits_w_zero \$file_new is undef\n")	if ! defined $file_new;
	&main::quit("fn_pad_digits_w_zero \$file_new eq ''\n")		if $file_new eq '';

	return $file_new if !$config::hash{pad_digits_w_zero}{value};

	# rm extra 0's
	$file_new =~ s/(^|\s+|\.|_)(\d{1,2})(x0)(\d{2})(\s+|\.|_|\..{3,4}$)/$1.$2."x".$4.$5/ieg;

	# pad NxN
	$file_new =~ s/(^|\s+|\.|_)(\dx)(\d)(\s+|\.|_|\..{3,4}$)/$1."0".$2."0".$3.$4/ie;	# NxN to 0Nx0N
	$file_new =~ s/(^|\s+|\.|_)(\d\dx)(\d)(\s+|\.|_|\..{3,4}$)/$1.$2."0".$3.$4/ie;		# NNxN to NNx0N
	$file_new =~ s/(^|\s+|\.|_)(\dx)(\d\d)(\s+|\.|_|\..{3,4}$)/$1."0".$2.$3.$4/ie;		# NxNN to 0NxNN

	# clean scene style
	# rm extra 0's
	$file_new =~ s/(^s|\s+s|\.s|_s)(\d{1,2})(e0)(\d{2})(\s+|\.|_|\..{3,4}$)/$1.$2."e".$4.$5/ieg;

	$file_new =~ s/(^s|\s+s|\.s|_s)(\d)(e)(\d)(\s+|\.|_|\..{3,4}$)/$1."0".$2."0".$3.$4.$5/ie;	# sNeN to S0Ne0N
	$file_new =~ s/(^s|\s+s|\.s|_s)(\d\d)(e)(\d)(\s+|\.|_|\..{3,4}$)/$1.$2.$3."0".$4.$5/ie;		# sNNeN to sNNe0N
	$file_new =~ s/(^s|\s+s|\.s|_s)(\d)(e)(\d\d)(\s+|\.|_|\..{3,4}$)/$1."0".$2.$3.$4.$5/ie;		# SNeNN to S0NeNN

	return $file_new;
}

sub fn_digits
{
	# remove leading digits (Track Nr)

	my $file_new = shift;
	&main::quit("fn_digits \$file_new is undef\n")	if ! defined $file_new;
	&main::quit("fn_digits \$file_new eq ''\n")     if $file_new eq '';

	$file_new =~ s/^\d*\s*// if $config::hash{digits}{value};

	return $file_new;
}

sub fn_enum
{
	my $file		= shift;
	my $file_new	= shift;

	&main::quit("fn_enum \$file is undef\n")							if ! defined $file;
	&main::quit("fn_enum \$file eq ''\n")								if $file eq '';
	&main::quit("fn_enum \$file '$file' is not a file or directory")	if !-f $file && !-d $file;

	return $file_new if ! $config::hash{enum}{value};

	if($config::hash{enum_pad}{value})
	{
		$a = "%.$config::hash{enum_pad_zeros}{value}"."d";
		$enum_count = sprintf($a, $enum_count);
	}
	my $enum_str = $enum_count;
	if($config::hash{enum_add}{value})
	{
		$enum_str = $config::enum_start_str.$enum_count.$config::enum_end_str;
	}

	my $ext = '';
	$ext = lc $1 if $file_new =~ m/\.(.+?)$/; # get file extension

	# ---------------------------------------------------------
	# enum number only - remove the rest of the filename
	if($config::hash{enum_opt}{value} == 0)
	{
		$file_new = $enum_str.'.'.$ext;
		$file_new = $enum_str if -d $file;
	}

	# ---------------------------------------------------------
	# Insert N at begining of filename

	elsif($config::hash{enum_opt}{value} == 1)
	{
		$file_new = "$enum_str$file_new";
	}

	# ---------------------------------------------------------
	# Insert N at end of filename

	elsif($config::hash{enum_opt}{value} == 2)
	{
		if(-d $file)
		{
			$file_new = "$file_new$enum_str";
		}
		else
		{
			# Insert N at end of filename but before file ext
			$file_new =~ s/(.*)(\..*$)/$1$enum_str$2/g;
		}
	}
	else
	{
		&main::quit("fn_enum unknown value set for \$config::hash{enum_opt}{value}\n" . Dumper($config::hash{enum_opt}));
	}
	$enum_count++;
	return $file_new;
}

sub fn_truncate
{
	my $file		= shift;
	my $file_new	= shift;

	&main::quit("fn_truncate \$file_new is undef\n")	if ! defined $file_new;
	&main::quit("fn_truncate \$file_new eq ''\n")		if $file_new eq '';

	my $trunc_length = 0;

	my $l = length $file_new;
	if($l > $config::hash{'max_fn_length'}{value} && $config::hash{'truncate_to'}{value} == 0)
	{
		&misc::plog(0, "sub fn_truncate: $file_new exceeds maximum filename length.");

		return;
	}

	if($l > $config::hash{'truncate_to'}{value} && $config::hash{truncate}{value} == 1)
	{
		my $file_ext		= $file_new;
		$file_ext			=~ s/^(.*)(\.)(.{3,4})$/$3/e;
		my $file_ext_length	= length $file_ext;		# doesn't include . in length

		# var for adjusted truncate to, gotta take into account file ext length
		$trunc_length = $config::hash{'truncate_to'}{value} - ($file_ext_length + 1);	# tl = truncate length

		# adjust tl to allow for added enum digits if enum mode is enabled
		if($config::hash{enum}{value} && $config::hash{enum_pad}{value})
		{
			$trunc_length = $trunc_length - $config::hash{enum_pad_zeros}{value};
		}
		elsif($config::hash{enum}{value})
		{
			$trunc_length = $trunc_length - length "$config::hash{enum}{value}_count";
		}

		# start truncating

		# from front
		if($config::hash{truncate_style}{value} == 0)
		{
			$file_new =~ s/^(.*)(.{$trunc_length})(\..{$file_ext_length})$/$2.$3/e;
		}

		# from end
		elsif($config::hash{truncate_style}{value} == 1)
		{
 			$file_new =~ s/^(.{$trunc_length})(.*)(\..{$file_ext_length})$/$1.$3/e;
		}

		# from middle
		elsif($config::hash{truncate_style}{value} == 2)
		{
			$trunc_length = int ($trunc_length - length $config::hash{trunc_char}{value}) / 2;

			$file_new =~ s/^(.{$trunc_length})(.*)(.{$trunc_length})(\..{$file_ext_length})$/$1.$config::hash{trunc_char}{value}.$3.$4/e;
		}
	}

	return $file_new;
}

sub fn_pre_clean
{
	my $FILE		= shift;	# flag
	my $file		= shift;	# file / string
	my $file_new	= shift;

	$file_new		= $file if ! defined $file_new;

	&main::quit("fn_pre_clean \$file is undef\n")	if ! defined $file;
	&main::quit("fn_pre_clean \$file eq ''\n")	if $FILE && $file eq '';
	&main::quit("fn_pre_clean \$FILE = 1 but '$file' is not a file and not a directory\n")	if $FILE && !-f $file && !-d $file;

	return $file_new if !$config::hash{cleanup_general}{value};

	# "fix Artist - - track" type filenames that can pop up when stripping words
	$file_new =~ s/-(\s|_|\.)+-/-/g;

	# remove leading chars
	$file_new =~ s/^(\s|_|\.|-)+//;

	# string rm trailing characters
	$file_new =~ s/(\s|_|\.|-)+$/$2/e if !$FILE;

	if($FILE && -f $file)
	{
		# rm trailing characters
		$file_new =~ s/(\s|_|\.|-)+(\..{3,4})$/$2/e;

		# I hate mpeg or jpeg as extensions personally :P
		$file_new =~ s/\.mpeg$/\.mpg/i;
		$file_new =~ s/\.jpeg$/\.jpg/i;
	}

	return $file_new;
}

sub fn_post_clean
{
	my $FILE = shift;
	my $f = shift;
	my $file_new = shift;

	$file_new = $f if !$file_new;

	&main::quit("fn_post_clean: \$f is undef\n")		if ! defined $f;
	&main::quit("fn_post_clean: \$f eq ''\n")			if $FILE && $f eq '';
	&main::quit("fn_post_clean: \$f '$f' not found\n")	if $FILE && !-f $f;

	return $file_new if !$config::hash{cleanup_general}{value};

	# remove childless brackets () [] {}
	$file_new =~ s/(\(|\[|\{)(\s|_|\.|\+|-)*(\)|\]|\})//g;

	# remove doubled up -'s
	$file_new =~ s/-(\s|_|\.)+-|--/-/g;

	# rm trailing characters
	$file_new =~ s/(\s|\+|_|\.|-)+(\..{3,4})$/$2/;

	# rm leading characters
	$file_new =~ s/^(\s|\+|_|\.|-)+//;

	# rm extra whitespaces
	$file_new =~ s/\s+/ /g;
	$file_new =~ s/$config::hash{space_character}{value}+/$config::hash{space_character}{value}/g;

	# change file extension to lower case and remove anyspaces before file ext
	$file_new =~ s/^(.*)(\..{3,4})$/$1.lc($2)/e if $FILE && -f $f;

	# remove trailing junk on directorys or strings
	if(-d $f || !$FILE)
	{
		$file_new =~ s/(\s|\+|_|\.|-)+$//;
	}

	return $file_new;
}

sub fn_front_a
{
	my $file_new = shift;
	&main::quit("fn_front_a \$file_new is undef\n")		if ! defined $file_new;
	&main::quit("fn_front_a \$file_new eq ''\n")		if $file_new eq '';

	return $file_new if !$config::hash{ins_start}{value};

	$file_new = $config::ins_front_str.$file_new;

	return $file_new;
}

sub fn_end_a
{
	my $file_new = shift;
	&main::quit("fn_end_a \$file_new is undef\n")	if ! defined $file_new;
	&main::quit("fn_end_a \$file_new eq ''\n")	    if $file_new eq '';

	return $file_new if $config::end_a;

	$file_new =~ s/(.*)(\..*?$)/$1$config::ins_end_str$2/g;

	return $file_new;
}

sub fn_pad_N_to_NN
{
	my $file_new = shift;
	&main::quit("fn_pad_N_to_NN \$file_new is undef\n")	if ! defined $file_new;
	&main::quit("fn_pad_N_to_NN \$file_new eq ''\n")	if $file_new eq '';

	return $file_new if !$config::hash{pad_N_to_NN}{value};

	$file_new =~ s/(\s+|_|\.)(\d{1,1})(\s+|_|\.)/$1."0".$2.$3/e;

	return $file_new;
}

sub fn_pad_dash
{
	my $file_new = shift;
	&main::quit("fn_pad_dash \$file_new is undef\n")	if ! defined $file_new;
	&main::quit("fn_pad_dash \$file_new eq ''\n")		if $file_new eq '';

	my $f = $file_new;

	return $file_new if !$config::hash{pad_dash}{value};

	$file_new =~ s/(\s*|_|\.)(-)(\s*|_|\.)/$config::hash{space_character}{value}."-".$config::hash{space_character}{value}/eg;

	return $file_new;
}

sub fn_rm_digits
{
	my $file_new = shift;
	&main::quit("fn_rm_digits \$file_new is undef\n")	if ! defined $file_new;
	&main::quit("fn_rm_digits \$file_new eq ''\n")	if $file_new eq '';

	return $file_new if !$config::hash{rm_digits}{value};

	$file_new =~ s/\d+//g;

	return $file_new;
}

sub fn_lc_all
{
	# lowercase all
	my $file_new = shift;
	&main::quit("fn_lc_all \$file_new is undef\n")	if ! defined $file_new;
	&main::quit("fn_lc_all \$file_new eq ''\n")		if $file_new eq '';

	return $file_new if !$config::hash{lc_all}{value};

	$file_new = lc($file_new);

	return $file_new;
}

sub fn_uc_all
{
	# uppercase all
	my $file_new = shift;
	&main::quit("fn_uc_all \$file_new is undef\n")	if ! defined $file_new;
	&main::quit("fn_uc_all \$file_new eq ''\n")		if $file_new eq '';

	return $file_new if !$config::hash{uc_all}{value};

	$file_new = uc($file_new);

	return $file_new;
}

sub fn_intr_char
{
	my $FILE = shift;
	# International Character translation
	# WARNING: This might break really badly on some systems, esp. non-Unix ones...
	# if you see alot of ? in your filenames, you need to add the correct codepage for the filesystem.

	my $file_new = shift;
	&main::quit("fn_intr_char \$file_new is undef\n")	if ! defined $file_new;
	&main::quit("fn_intr_char \$file_new eq ''\n")		if $FILE && $file_new eq '';

	my $f = $file_new;

	return $file_new if !$config::hash{intr_char}{value};

	# Nordic/Germanic characters
	$file_new =~ s/Å/Aa/g;
	$file_new =~ s/Ä/Ae/g;
	$file_new =~ s/À/A/g;
	$file_new =~ s/ä/ae/g;

	$file_new =~ s/ß/ss/g;

	$file_new =~ s/É/E/g;

	$file_new =~ s/Í/I/g;

	$file_new =~ s/Ñ/N/g;

	$file_new =~ s/Ø/O/g;
	$file_new =~ s/Ö/Oe/g;
	$file_new =~ s/Ô/Oo/g;

	$file_new =~ s/Ü/Ue/g;
	$file_new =~ s/Ù/U/g;

	# Lowercase variants
	$file_new =~ s/à/a/g;
	$file_new =~ s/á/a/g;	# mems 1st addition to int support
	$file_new =~ s/â/a/g;
	$file_new =~ s/å/aa/g;
	$file_new =~ s/æ/ae/g;
	$file_new =~ s/ä/ae/g;

	$file_new =~ s/ç/c/g;

	$file_new =~ s/é/e/g;
	$file_new =~ s/è/e/g;

	$file_new =~ s/í/i/g;

	$file_new =~ s/ñ/n/g;

	$file_new =~ s/ô/oo/g;
	$file_new =~ s/ö/oe/g;
	$file_new =~ s/ò/o/g;
	$file_new =~ s/ø/o/g;

	$file_new =~ s/ú/u/g;
	$file_new =~ s/ü/ue/g;

	# Remove any remaining problematic characters
	$file_new =~ s/['']/'/g;  # Smart quotes to regular apostrophe
	$file_new =~ s/[""]/"/g;  # Smart quotes to regular quotes
	$file_new =~ s/…/.../g;   # Ellipsis to three dots

	return $file_new;
}

sub fn_case
{
	my $FILE = shift;
	my $file_new = shift;
	&main::quit("fn_case \$file_new is undef\n")	if ! defined $file_new;
	&main::quit("fn_case \$file_new eq ''\n")		if $FILE && $file_new eq '';

	my $f = $file_new;

	return $file_new if !$config::hash{case}{value};

	$file_new =~ s/(^| |\.|_|\(|-)([A-Za-z������������������������������])(([A-Za-z������������������������������]|\'|\�|\�|\�)*)/$1.uc($2).lc($3)/eg;

	return $file_new;
}


1;
