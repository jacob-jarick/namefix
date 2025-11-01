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
	if(&state::get('stop'))
	{
		&misc::plog(1, "STOP flag set, aborting fixname");
		return 0;
	}

    # -----------------------------------------
	# Vars
    # -----------------------------------------

	my $file 	= shift;	# should be full or relative path
	my $path	= '';

	# ($dir, $file, $path) =  &misc::get_file_info($file);

	my ($type, $file_path, $dir, $file_name, $file_ext) = &misc::get_file_all($file);

	$file_ext = $file_ext // '';

	chdir $dir;

    my $IS_AUDIO_FILE	    = 0;
    my $tag 		        = 0;
    my $file_ext_length	    = 0;
    my $trunc_char_length	= 0;
    my $TAGS_CHANGED        = 0;

    my $newfile		        = $file_name;    
    my $tmpfile		        = '';

	# Only check for audio file extensions on actual files, not directories
	$IS_AUDIO_FILE = 1 if -f $file_path && $file_name =~ /\.($globals::id3_ext_regex)$/i;

	# check file exists
	if($IS_AUDIO_FILE && $config::hash{id3_mode}{value} && !-f $file_path)
	{
		&misc::plog(0, "check file exists error !-f '$file_path'\n\t\$file_name = '$file_name'\n\t\$dir = '$dir'\n\t\$file_path = '$file_path'\n\tIS_AUDIO_FILE = '$IS_AUDIO_FILE'\n\t\$globals::id3_ext_regex = '$globals::id3_ext_regex'");
		return;
	}

    # -----------------------------------------
	# make sure file is allowed to be renamed
    # -----------------------------------------

    &misc::quit("ERROR IGNORE_FILE_TYPE is undef\n") if !defined $config::hash{ignore_file_type}{value};

    my $RENAME = 0;

    # file extionsion check
    $RENAME = 1 if -f $file_path && ($config::hash{ignore_file_type}{value} || $file_name =~ /\.($config::hash{file_ext_2_proc}{value})$/i);

	# dir check, is a directory, dir mode is enabled
    $RENAME = 1 if $config::hash{proc_dirs}{value} && -d $file_path;

	# processing all file types & dirs
    $RENAME = 1 if $config::hash{proc_dirs}{value} && $config::hash{ignore_file_type}{value};

	# didnt match filter
    return if $config::hash{filter}{value} && !&filter::match($file_name);

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

		if ($globals::CLI) 
		{
			print "\n=== Processing Directory: $dir ===\n";
		}
		else 
		{
			&nf_print::blank();
			&nf_print::p($dir);
		}
	}

	#------------------------------------------------------------------------------
	# EXIF data processing

	# CLI only as its not really needed in gui mode
	# currently it just prints and returns
	# printing is probably ugly

	if($globals::CLI && $config::hash{exif_show}{value} && &jpegexif::file_supports_exif($file_path))
	{
		my $exif_tags_ref = &jpegexif::list_exif_tags($file_path);

		if(defined $exif_tags_ref && ref($exif_tags_ref) eq 'HASH')
		{
			print "\n=== EXIF Data for $file_path ===\n";
			# loop through tags and print them
			for my $tag (sort keys %$exif_tags_ref)
			{
				print "\t$tag: $exif_tags_ref->{$tag}\n";
			}
			print "=== End EXIF Data ===\n\n";
		}
		else
		{
			print "No EXIF data found for $file_path\n";
		}
	}

	# EXIF data removal

	if($config::hash{exif_rm_all}{value} && &jpegexif::file_supports_exif($file_path))
	{
		my $writable_tag_count = &jpegexif::writable_exif_tag_count($file_path);
		if($writable_tag_count > 0)
		{
			&misc::plog(2, "'$file_path' has $writable_tag_count writable EXIF tags");

			if(!$globals::PREVIEW)
			{
				jpegexif::remove_exif_data($file_path);
				$globals::exif_rm_count++;
				&misc::plog(2, "'$file' removed exif data");
			}
			else
			{
				&misc::plog(2, "'$file_path' would remove exif data (preview mode)");
			}			
		}
		else
		{
			&misc::plog(2, "'$file_path' has no EXIF data, skipping removal");
			return;
		}
	}

	#------------------------------------------------------------------------------
	# Fetch & process audio tags
	# $tag = 1 only if tags are found & id3 mode is enabled

	my %tags_h	    = ();
	my %tags_h_new	= ();

	if($config::hash{id3_mode}{value} && $IS_AUDIO_FILE)
	{
		my $ref		= &mp3::get_tags($file_path);
		%tags_h		= %$ref;
		%tags_h_new	= %tags_h;
		$tag		= 1;

		my @tags_to_fix = ('artist', 'title', 'album', 'comment');
		for my $k(@tags_to_fix)
		{
			&misc::quit("ERROR processing audio file $file_path - tag $k is undef") if ! defined $tags_h_new{$k};
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

	if($config::hash{id3_fn_from_tag}{value} && $IS_AUDIO_FILE)
	{
		my $ref		= &mp3::get_tags($file_path);
		%tags_h		= %$ref;

		# allow artist override
		if($config::hash{id3_set_artist}{value} && defined $config::hash{id3_art_str}{value} && $config::hash{id3_art_str}{value} ne '')
		{
			$tags_h{artist} = $config::hash{id3_art_str}{value};
		}

		# allow title override
		if($config::hash{id3_set_title}{value} && defined $config::hash{id3_tit_str}{value} && $config::hash{id3_tit_str}{value} ne '')
		{
			$tags_h{title} = $config::hash{id3_tit_str}{value};
		}

		# allow album override
		if($config::hash{id3_set_album}{value} && defined $config::hash{id3_alb_str}{value} && $config::hash{id3_alb_str}{value} ne '')
		{
			$tags_h{album} = $config::hash{id3_alb_str}{value};
		}

		# allow track override
		if($config::hash{id3_set_track}{value} && defined $config::hash{id3_tra_str}{value} && $config::hash{id3_tra_str}{value} ne '')
		{
			$tags_h{track} = $config::hash{id3_tra_str}{value};

			# always zero pad track number
			$tags_h{track} = sprintf("%02d", $tags_h{track}) if defined $tags_h{track};
		}

		my $fn_from_tags = '';	# always start blank
		# my $fn_ext = $file;
		# $fn_ext =~ s/^(.*)(\.)(.{3,4})$/$3/e;
		my $id3_fn_gen_error_count = 0;

		# validate tags

		# ARTIST
		if($tags_h{artist} eq '')
		{
			$id3_fn_gen_error_count++;
			&misc::plog(1, "'$file' id3 has no artist set, skipping filename generation");
		}

		# TITLE
		if($tags_h{title} eq '')
		{
			$id3_fn_gen_error_count++;
			&misc::plog(1, "'$file' id3 has no title set, skipping filename generation");
		}

		# ALBUM
		if($tags_h{album} eq '' && ($config::hash{id3_fn_style}{value} == 2 || $config::hash{id3_fn_style}{value} == 3))
		{
			$id3_fn_gen_error_count++;
			&misc::plog(1, "'$file' id3 has no album set, skipping filename generation. Style $config::hash{id3_fn_style}{value} requires album");
		}

		# TRACK
		if
		(
			$tags_h{track} eq '' && 
			( $config::hash{id3_fn_style}{value} == 1 || $config::hash{id3_fn_style}{value} == 3)
		)
		{
			$id3_fn_gen_error_count++;
			&misc::plog(1, "'$file' id3 has no track set, skipping filename generation. Style $config::hash{id3_fn_style}{value} requires track");
		}

		# generate filename if no errors
		if(!$id3_fn_gen_error_count)
		{
			if($config::hash{id3_fn_style}{value} == 0)
			{
				$fn_from_tags = "$tags_h{artist} - $tags_h{title}.$file_ext";
			}
			elsif($config::hash{id3_fn_style}{value} == 1)
			{
				$fn_from_tags = "$tags_h{artist} - $tags_h{track} - $tags_h{title}.$file_ext";
			}
			elsif($config::hash{id3_fn_style}{value} == 2)
			{
				$fn_from_tags = "$tags_h{artist} - $tags_h{album} - $tags_h{title}.$file_ext";
			}
			elsif($config::hash{id3_fn_style}{value} == 3)
			{
				$fn_from_tags = "$tags_h{artist} - $tags_h{album} - $tags_h{track} - $tags_h{title}.$file_ext";
			}
			else
			{
				&misc::quit("ERROR id3_fn_style '$config::hash{id3_fn_style}{value}' is invalid");
			}

			$newfile = $fn_from_tags;
			&misc::plog(2, "'$file_path' generated new filename from id3 tags: '$newfile'");
		}
	}

	#------------------------------------------------------------------------------

	$newfile = &run_fixname_subs($file_path, $newfile);

	# End of cleanups

	#==========================================================================================================================================
	# check for and apply filename/ id3 changes
	#==========================================================================================================================================

	# set user entered audio tags overrides if any

	if($config::hash{id3_set_artist}{value} && $IS_AUDIO_FILE)
	{
		$tags_h_new{artist} = $config::hash{id3_art_str}{value};
		$tag	= 1;
	}

	if($config::hash{id3_set_album}{value} && $IS_AUDIO_FILE)
	{
		$tags_h_new{album} = $config::hash{id3_alb_str}{value};
		$tag	= 1;
	}

	if($config::hash{id3_set_genre}{value} && $IS_AUDIO_FILE)
	{
		$tags_h_new{genre} = $config::hash{id3_gen_str}{value};
		$tag	= 1;
	}

	if($config::hash{id3_set_year}{value} && $IS_AUDIO_FILE)
	{
		$tags_h_new{year} = $config::hash{id3_year_str}{value};
		$tag	= 1;
	}

	if($config::hash{id3_set_comment}{value} && $IS_AUDIO_FILE)
	{
		$tags_h_new{comment} = $config::hash{id3_com_str}{value};
		$tag	= 1;
	}

	# set title tag if specified via CLI --id3-tit
	if(defined $config::hash{id3_tit_str}{value} && $config::hash{id3_tit_str}{value} ne '' && $IS_AUDIO_FILE)
	{
		$tags_h_new{title} = $config::hash{id3_tit_str}{value};
		$tag	= 1;
	}

	# set track tag if specified via CLI --id3-tra  
	if(defined $config::hash{id3_tra_str}{value} && $config::hash{id3_tra_str}{value} ne '' && $IS_AUDIO_FILE)
	{
		$tags_h_new{track} = $config::hash{id3_tra_str}{value};
		$tag	= 1;
	}

	# rm mp3 id3v2 tags
    if($IS_AUDIO_FILE && $config::hash{id3_tags_rm}{value})
	{
        if(!$globals::PREVIEW)
		{
            &mp3::rm_tags($file_path);
        }
        else
		{
            $globals::tags_rm_count++;
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
			&misc::plog(3, "'$file_path' update ID3 tags");	
			if(!$globals::PREVIEW)
			{
				&mp3::write_tags("$file_path", \%tags_h_new);
			}
			&misc::plog(2, "'$file_path' ID3 tags updated");
		}
	}

	if($file_name ne $newfile)
	{
		if(!$globals::PREVIEW)
		{
			if(!&fn_rename($file_path, $newfile) )
			{
				&misc::plog(0, "fixname: '$newfile' cannot perform rename, file already exists");
				return 0;
			}
		}
		else
		{
			$globals::change++; # increment change for preview count
		}
	}

	if ($globals::CLI) 
	{
		if($config::hash{html_hack}{value})
		{
			&cli_print::print
			(
				$file_name,
				$newfile,

				\%tags_h,
				\%tags_h_new,
				'normal'
			);
		}
		# current CLI output: simple before -> after format
		elsif ($file_name ne $newfile) 
		{
			print "'$file_name' -> '$newfile'\n";
		}
		elsif ($config::hash{debug}{value} >= 2)
		{
			print "'$file_name' (no change)\n";
		}
	}
	else 
	{
		# GUI output: only show if there are changes or high debug level
		if ($file_name ne $newfile || $TAGS_CHANGED)
		{
			&nf_print::p
			(
				$file_name,
				$newfile,

				\%tags_h,
				\%tags_h_new
			);
		}
	}
};

#==========================================================================================================================================

# returns 1 if successful rename, errors are printed to console

# this code looks messy but it does need to be laid out with the doubled up "if(-e $newfile && !$config::hash{overwrite}{value}) "
# bloody fat32 returns positive when we don't want it, ie case correcting

sub fn_rename
{
	if(&state::get('stop'))
	{
		&misc::plog(1, "STOP flag set, aborting rename");
		return 0;
	}

	my $file	= shift;
	my $newfile	= shift;

	&misc::quit("fn_rename \$file is undef\n")		if ! defined $file;
	&misc::quit("fn_rename \$file eq ''\n")			if $file eq '';

    &misc::quit("fn_rename \$newfile is undef\n")	if ! defined $newfile;
	&misc::quit("fn_rename \$newfile eq ''\n")		if $newfile eq '';

	my $file_name = &misc::get_file_name($file);
	&misc::plog(3, "rename '$file_name' to '$newfile'");

	my $dir		= &misc::get_file_parent_dir($file);
	$newfile	= "$dir/$newfile";
	my $tmpfile = $newfile.'-FSFIX';

	# updated fat32 fix to only do it if the names are the same when lowercased
	if($config::hash{fat32fix}{value} && lc $file eq lc $newfile) 	# work around case insensitive filesystem renaming problems
	{
		if( -e $tmpfile && !$config::hash{overwrite}{value})
		{
			$globals::FOUND_TMP++;
			$globals::tmpfilelist .= "$tmpfile\n";
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
			$globals::SUGGEST_FSFIX++;
			&misc::plog(0, "fn_rename: '$newfile' refusing to rename, file exists");
			return 0;
		}
		rename $file, $newfile;
		&undo::add($file, "$dir/$newfile");
	}
	$globals::change++;
	return 1;
}

# this code has been segmented from the sub fixname in order for blockrename to take advantage

sub run_fixname_subs
{
	my $file	= shift;
	my $newfile	= shift;

	&misc::quit("run_fixname_subs \$file is undef\n")		        if ! defined $file;
	&misc::quit("run_fixname_subs \$file eq ''\n")			        if $file eq '';
	&misc::quit("run_fixname_subs \$file isn't a dir or file\n")	if !-f $file && !-d $file;

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

	# 7bit ASCII conversion
	$temp = $newfile;
	$newfile = &to_7bit_ascii($newfile);
	&misc::plog(3, "to_7bit_ascii: '$temp' -> '$newfile'") if $temp ne $newfile;
	
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

	&misc::quit("fn_kill_cwords \$file is undef\n")	if ! defined $file;
	&misc::quit("fn_kill_cwords \$file eq ''\n")	if $file eq '';

	$file_new = $file if !defined $file_new || $file_new eq '';

	if($config::hash{kill_cwords}{value})
	{
		# PERFORMANCE FIX: Complete rewrite to eliminate catastrophic backtracking
		# Instead of complex regex alternations, use simple word boundary matching
		
		foreach my $word (@globals::kill_words_arr) 
		{
			if(-d $file) 
			{
				# For directories, allow removal at end of string
				$file_new =~ s/\b\Q$word\E\b//ig;
			} 
			else 
			{
				# For files, be careful not to remove from file extension
				# Split into name and extension, process name only
				if ($file_new =~ /^(.+)(\..+)$/) 
				{
					my ($name, $ext) = ($1, $2);
					$name =~ s/\b\Q$word\E\b//ig;
					$file_new = $name . $ext;
				} 
				else 
				{
					# No extension, process entire string
					$file_new =~ s/\b\Q$word\E\b//ig;
				}
			}
		}
	}
	return $file_new;
}

sub fn_replace
{
	my $FILE		= shift;
	my $file_new	= shift;

	&misc::quit("fn_replace \$file_new is undef\n")	if ! defined $file_new;
	&misc::quit("fn_replace \$file_new eq ''\n")	if $FILE && $file_new eq '';

	return $file_new if !$config::hash{replace}{value};

	my $rm = $config::hash{ins_str_old}{value};
	if(!$config::hash{remove_regex}{value})
	{
		$rm = quotemeta $config::hash{ins_str_old}{value};
	}

	$file_new =~ s/($rm)/$config::hash{ins_str}{value}/ig;

	return $file_new;
}

sub fn_kill_sp_patterns
{
	my $file_new = shift;
	&misc::quit("fn_kill_sp_patterns \$file_new is undef\n")	if ! defined $file_new;
	&misc::quit("fn_kill_sp_patterns \$file_new eq ''\n")		if $file_new eq '';

	return $file_new if !$config::hash{kill_sp_patterns}{value};

	for my $pattern (@globals::kill_patterns_arr)
	{
		$file_new =~ s/$pattern//ig;
	}

	return $file_new;
}

sub fn_unscene
{
	my $file_new = shift;

	&misc::quit("fn_unscene \$file_new is undef\n")	if ! defined $file_new;
	&misc::quit("fn_unscene \$file_new eq ''\n")	if $file_new eq '';

	return $file_new  if !$config::hash{unscene}{value};

	$file_new =~ s/(S)(\d+)(E)(\d+)/$2.qw(x).$4/ie;

	return $file_new;
}

sub fn_scene
{
	my $file_new = shift;
	&misc::quit("fn_scene \$file_new is undef\n")	if ! defined $file_new;
	&misc::quit("fn_scene \$file_new eq ''\n")		if $file_new eq '';

	return $file_new if !$config::hash{scene}{value};

	$file_new =~ s/(^|\W)(\d+)(x)(\d+)/$1.qw(S).$2.qw(E).$4/ie;

	return $file_new;
}

# underscores to spaces
sub fn_spaces
{
	my $FILE		= shift;
	my $file_new	= shift;

	&misc::quit("fn_spaces \$file_new is undef\n")	if ! defined $file_new;
	&misc::quit("fn_spaces \$file_new eq ''\n") 	if $FILE && $file_new eq '';

	return $file_new if !$config::hash{spaces}{value};

	$file_new =~ s/(\s|_)+/$config::hash{space_character}{value}/g;

	return $file_new;
}

sub fn_sp_char
{
	my $file_new = shift;
	&misc::quit("fn_sp_char \$file_new is undef\n")	if ! defined $file_new;
	&misc::quit("fn_sp_char \$file_new eq ''\n")	if $file_new eq '';

	return $file_new if !$config::hash{sp_char}{value};

	$file_new =~ s/[\~\@\%\{\}\[\]\"\<\>\!\`\'\,\#\(|\)]//g;

	return $file_new;
}

# split supposed episode numbers, eg 0103 to 01x03
# trys to avoid obvious years

sub fn_split_dddd
{
	my $file_new = shift;

	&misc::quit("fn_split_dddd \$file_new is undef\n")	if ! defined $file_new;
	&misc::quit("fn_split_dddd \$file_new eq ''\n")		if $file_new eq '';

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

	&misc::quit("fn_case_fl: \$file_new is undef\n")	if !defined $file_new;
	&misc::quit("fn_case_fl: \$file_new eq ''\n")		if $FILE && $file_new eq '';

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

	&misc::quit("fn_sp_word \$file is undef\n")		if ! defined $file;
	&misc::quit("fn_sp_word \$file eq ''\n")		if $FILE && $file eq '';

	my $file_new = shift;
	&misc::quit("fn_sp_word \$file_new is undef\n")	if ! defined $file_new;
	&misc::quit("fn_sp_word \$file_new eq ''\n")	if $FILE && $file_new eq '';

	return $file_new if !$config::hash{word_special_casing}{value};
	foreach my $word(@globals::word_casing_arr)
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

	&misc::quit("fn_dot2space \$FILE value '$FILE' is invalid\n")	if $FILE != 0 && $FILE != 1;
	&misc::quit("fn_dot2space \$file is undef\n")					if ! defined $file;
	&misc::quit("fn_dot2space \$file eq ''\n")						if $FILE && $file eq '';

	return $file_new if !$config::hash{dot2space}{value};

	if($FILE && $file_new =~ m/^(.*)\.(.*?)$/g)	# is file and not a directory
	{
		my $name	= $1;
		my $ext		= $2;
		$name		=~ s/\./$config::hash{space_character}{value}/g;
		$file_new	= "$name.$ext";
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
	&misc::quit("fn_pad_digits \$file_new is undef\n")	if ! defined $file_new;
	&misc::quit("fn_pad_digits \$file_new eq ''\n")		if $file_new eq '';

	return $file_new if !$config::hash{pad_digits}{value};

	my $tmp = $config::hash{space_character}{value}."-".$config::hash{space_character}{value};
	my $space = $config::hash{space_character}{value};

	# beginning of filename
	$file_new =~ s/^(\d{2}|\d+x\d+|s\d+e\d+)($space)+/$1.$tmp/ie;
	# middle of filename
	$file_new =~ s/($space)+(\d{2}|\d+x\d+|s\d+e\d+)($space)+/$tmp.$2.$tmp/ie;
	# end of filename
	$file_new =~ s/($space)+(\d{2}|\d+x\d+|s\d+e\d+)(\..{3,4}$)/$tmp.$2.$3/ie;

	return $file_new;
}

sub fn_pad_digits_w_zero
{
	my $file_new = shift;
	&misc::quit("fn_pad_digits_w_zero \$file_new is undef\n")	if ! defined $file_new;
	&misc::quit("fn_pad_digits_w_zero \$file_new eq ''\n")		if $file_new eq '';

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
	&misc::quit("fn_digits \$file_new is undef\n")	if ! defined $file_new;
	&misc::quit("fn_digits \$file_new eq ''\n")     if $file_new eq '';

	$file_new =~ s/^\d*\s*// if $config::hash{digits}{value};

	return $file_new;
}

sub fn_enum
{
	my $file		= shift;
	my $file_new	= shift;

	&misc::quit("fn_enum \$file is undef\n")							if ! defined $file;
	&misc::quit("fn_enum \$file eq ''\n")								if $file eq '';
	&misc::quit("fn_enum \$file '$file' is not a file or directory")	if !-f $file && !-d $file;

	return $file_new if ! $config::hash{enum}{value};

	if($config::hash{enum_pad}{value})
	{
		$a = "%.$config::hash{enum_pad_zeros}{value}"."d";
		$enum_count = sprintf($a, $enum_count);
	}
	my $enum_str = $enum_count;
	if($config::hash{enum_add}{value})
	{
		$enum_str = $config::hash{enum_start_str}{value}.$enum_count.$config::hash{enum_end_str}{value};
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
		&misc::quit("fn_enum unknown value set for \$config::hash{enum_opt}{value}\n" . Dumper($config::hash{enum_opt}));
	}
	$enum_count++;
	return $file_new;
}

sub fn_truncate
{
	my $file		= shift;
	my $file_new	= shift;

	&misc::quit("fn_truncate \$file_new is undef\n")	if ! defined $file_new;
	&misc::quit("fn_truncate \$file_new eq ''\n")		if $file_new eq '';

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

	&misc::quit("fn_pre_clean \$file is undef\n")	if ! defined $file;
	&misc::quit("fn_pre_clean \$file eq ''\n")	if $FILE && $file eq '';
	&misc::quit("fn_pre_clean \$FILE = 1 but '$file' is not a file and not a directory\n")	if $FILE && !-f $file && !-d $file;

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
	my $FILE		= shift;
	my $f			= shift;
	my $file_new	= shift;

	$file_new = $f if !$file_new;

	&misc::quit("fn_post_clean: \$f is undef\n")		if ! defined $f;
	&misc::quit("fn_post_clean: \$f eq ''\n")			if $FILE && $f eq '';
	&misc::quit("fn_post_clean: \$f '$f' not found\n")	if $FILE && !-f $f;

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
	&misc::quit("fn_front_a \$file_new is undef\n")		if ! defined $file_new;
	&misc::quit("fn_front_a \$file_new eq ''\n")		if $file_new eq '';

	return $file_new if !$config::hash{ins_start}{value};

	$file_new = $config::hash{ins_front_str}{value}.$file_new;

	return $file_new;
}

sub fn_end_a
{
	my $file_new = shift;
	&misc::quit("fn_end_a \$file_new is undef\n")	if ! defined $file_new;
	&misc::quit("fn_end_a \$file_new eq ''\n")	    if $file_new eq '';

	return $file_new if ! $config::hash{ins_end}{value};

	$file_new =~ s/(.*)(\..*?$)/$1$config::hash{ins_end_str}{value}$2/g;

	return $file_new;
}

sub fn_pad_N_to_NN
{
	my $file_new = shift;
	&misc::quit("fn_pad_N_to_NN \$file_new is undef\n")	if ! defined $file_new;
	&misc::quit("fn_pad_N_to_NN \$file_new eq ''\n")	if $file_new eq '';

	return $file_new if !$config::hash{pad_N_to_NN}{value};

	$file_new =~ s/(\s+|_|\.)(\d{1,1})(\s+|_|\.)/$1."0".$2.$3/e;

	return $file_new;
}

sub fn_pad_dash
{
	my $file_new = shift;
	&misc::quit("fn_pad_dash \$file_new is undef\n")	if ! defined $file_new;
	&misc::quit("fn_pad_dash \$file_new eq ''\n")		if $file_new eq '';

	my $f = $file_new;

	return $file_new if !$config::hash{pad_dash}{value};

	$file_new =~ s/(\s*|_|\.)(-)(\s*|_|\.)/$config::hash{space_character}{value}."-".$config::hash{space_character}{value}/eg;

	return $file_new;
}

sub fn_rm_digits
{
	my $file_new = shift;
	&misc::quit("fn_rm_digits \$file_new is undef\n")	if ! defined $file_new;
	&misc::quit("fn_rm_digits \$file_new eq ''\n")	if $file_new eq '';

	return $file_new if !$config::hash{rm_digits}{value};

	$file_new =~ s/\d+//g;

	return $file_new;
}

sub fn_lc_all
{
	# lowercase all
	my $file_new = shift;
	&misc::quit("fn_lc_all \$file_new is undef\n")	if ! defined $file_new;
	&misc::quit("fn_lc_all \$file_new eq ''\n")		if $file_new eq '';

	return $file_new if !$config::hash{lc_all}{value};

	$file_new = lc($file_new);

	return $file_new;
}

sub fn_uc_all
{
	# uppercase all
	my $file_new = shift;
	&misc::quit("fn_uc_all \$file_new is undef\n")	if ! defined $file_new;
	&misc::quit("fn_uc_all \$file_new eq ''\n")		if $file_new eq '';

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
	&misc::quit("fn_intr_char \$file_new is undef\n")	if ! defined $file_new;
	&misc::quit("fn_intr_char \$file_new eq ''\n")		if $FILE && $file_new eq '';

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
	#$file_new =~ s/á/a/g;	# mems 1st addition to int support - removed, non germanic
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

sub to_7bit_ascii
{
	my $file_new = shift;

	# emdash and endash to regular dash
	$file_new =~ s/[—–]/-/g;
	$file_new =~ s/[“”]/"/g;  # Smart quotes to regular quotes
	$file_new =~ s/[‘’]/'/g;  # Smart quotes to regular apostrophe
	$file_new =~ s/[´`]/'/g;  # Accent to regular apostrophe
	$file_new =~ s/·/./g;     # Middle dot to regular dot
	$file_new =~ s/…/.../g;   # Ellipsis to three dots
	$file_new =~ s/[«»]/"/g;  # Guillemets to quotes
	$file_new =~ s/[‹›]/'/g;  # Single guillemets to apostrophe
	$file_new =~ s/[†‡]/+/g;  # Daggers to plus
	$file_new =~ s/[°]/o/g;   # Degree symbol to o
	$file_new =~ s/[¡]/!/g;   # Inverted exclamation
	$file_new =~ s/[¿]/?/g;   # Inverted question mark

	# Currency symbols
	$file_new =~ s/[¢]/c/g;   # Cent
	$file_new =~ s/[£]/L/g;   # Pound
	$file_new =~ s/[¥]/Y/g;   # Yen
	$file_new =~ s/[€]/E/g;   # Euro

	# Mathematical symbols
	$file_new =~ s/[×]/x/g;   # Multiplication
	$file_new =~ s/[÷]/\//g;  # Division
	$file_new =~ s/[±]/+-/g;  # Plus-minus
	$file_new =~ s/[²]/2/g;   # Superscript 2
	$file_new =~ s/[³]/3/g;   # Superscript 3
	$file_new =~ s/[¹]/1/g;   # Superscript 1
	$file_new =~ s/[¼]/1\/4/g; # One quarter
	$file_new =~ s/[½]/1\/2/g; # One half
	$file_new =~ s/[¾]/3\/4/g; # Three quarters

	# A with diacritics
	$file_new =~ s/[ÀÁÂÃÄÅĀĂĄǺǻ]/A/g;
	$file_new =~ s/[àáâãäåāăąǻ]/a/g;
	$file_new =~ s/[Æ]/AE/g;
	$file_new =~ s/[æ]/ae/g;

	# C with diacritics
	$file_new =~ s/[ÇĆĈĊČ]/C/g;
	$file_new =~ s/[çćĉċč]/c/g;

	# D with diacritics
	$file_new =~ s/[ÐĎĐ]/D/g;
	$file_new =~ s/[ðďđ]/d/g;

	# E with diacritics
	$file_new =~ s/[ÈÉÊËĒĔĖĘĚ]/E/g;
	$file_new =~ s/[èéêëēĕėęě]/e/g;

	# G with diacritics
	$file_new =~ s/[ĜĞĠĢ]/G/g;
	$file_new =~ s/[ĝğġģ]/g/g;

	# H with diacritics
	$file_new =~ s/[ĤĦ]/H/g;
	$file_new =~ s/[ĥħ]/h/g;

	# I with diacritics
	$file_new =~ s/[ÌÍÎÏĨĪĬĮİ]/I/g;
	$file_new =~ s/[ìíîïĩīĭįı]/i/g;

	# J with diacritics
	$file_new =~ s/[Ĵ]/J/g;
	$file_new =~ s/[ĵ]/j/g;

	# K with diacritics
	$file_new =~ s/[Ķ]/K/g;
	$file_new =~ s/[ķ]/k/g;

	# L with diacritics
	$file_new =~ s/[ĹĻĽĿŁ]/L/g;
	$file_new =~ s/[ĺļľŀł]/l/g;

	# N with diacritics
	$file_new =~ s/[ÑŃŅŇŊ]/N/g;
	$file_new =~ s/[ñńņňŋ]/n/g;

	# O with diacritics
	$file_new =~ s/[ÒÓÔÕÖØŌŎŐ]/O/g;
	$file_new =~ s/[òóôõöøōŏő]/o/g;
	$file_new =~ s/[Œ]/OE/g;
	$file_new =~ s/[œ]/oe/g;

	# R with diacritics
	$file_new =~ s/[ŔŖŘ]/R/g;
	$file_new =~ s/[ŕŗř]/r/g;

	# S with diacritics
	$file_new =~ s/[ŚŜŞŠ]/S/g;
	$file_new =~ s/[śŝşš]/s/g;
	$file_new =~ s/[ß]/ss/g;  # German eszett

	# T with diacritics
	$file_new =~ s/[ŢŤŦ]/T/g;
	$file_new =~ s/[ţťŧ]/t/g;

	# U with diacritics
	$file_new =~ s/[ÙÚÛÜŨŪŬŮŰŲ]/U/g;
	$file_new =~ s/[ùúûüũūŭůűų]/u/g;

	# W with diacritics
	$file_new =~ s/[Ŵ]/W/g;
	$file_new =~ s/[ŵ]/w/g;

	# Y with diacritics
	$file_new =~ s/[ÝŶŸ]/Y/g;
	$file_new =~ s/[ýÿŷ]/y/g;

	# Z with diacritics
	$file_new =~ s/[ŹŻŽ]/Z/g;
	$file_new =~ s/[źżž]/z/g;

	# Special Nordic/Germanic characters
	$file_new =~ s/[Þ]/Th/g; # Thorn
	$file_new =~ s/[þ]/th/g; # Thorn lowercase

	# Remove all UTF-8 combining diacritical marks (zalgo-style accents)
	# This removes combining characters like t̵̛̯̰̤̳͒̀̎̔͌̓̔̍̈́͐̚ḛ̶͑̀͌̄̀͝š̸̛͙͉̺̻̫ť̴̻̈̐̑͋́̌͆͋̑̕͠͠ → test
	$file_new =~ s/\p{M}//g;  # Remove all combining marks (diacriticals)

	# Remove any remaining non-ASCII characters (fallback)
	$file_new =~ s/[^\x00-\x7F]//g;

	return $file_new;
}

sub fn_case
{
	my $FILE = shift;
	my $file_new = shift;
	&misc::quit("fn_case \$file_new is undef\n")	if ! defined $file_new;
	&misc::quit("fn_case \$file_new eq ''\n")		if $FILE && $file_new eq '';

	my $f = $file_new;

	return $file_new if !$config::hash{case}{value};

	$file_new =~ s/(^| |\.|_|\(|-)([A-Za-zÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿ])(([A-Za-zÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿ]|\'|\')*)/$1.uc($2).lc($3)/eg;

	return $file_new;
}


1;
