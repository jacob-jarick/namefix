# home to all my small misc functions.
package misc;
require Exporter;
@ISA = qw(Exporter);



use strict;
use warnings;

my @output = ();

sub ci_sort
{
	my @sortme2 = sort { lc($a) cmp lc($b) } @_;
	return @sortme2;
}

# plog - print log

# Notes:
# Since i will be logging all subs (excluding plog itself, plug cannot call any namefix subs (recursion errors which locked linux on my system)

sub plog
{
	my $level	= shift;
	my $text	= shift;

	if(!$config::CLI) # gui mode
	{
		if($text !~ /\n/ && length $text > 2 && $text ne ' ' && $text ne '')
		{
			$text .= "\n";
		}
		push @output, "$text";
		if(scalar @output > 200)
		{
			@output = @output[scalar @output - 50 .. scalar @output];
		}
		if(defined $main::log_box) # plog can occur before gui is ready
		{
		$main::log_box->Contents(@output);
			$main::log_box->GotoLineNumber(scalar @output);
		}
	}

	if($level == 0)
	{
		$text = "ERROR>$text";

		# CLI will (for now) always spit out & log errors
		if($config::CLI)
		{
			open(FILE, ">>$main::log_file");
			print FILE "$text\n";
			close(FILE);

			print "$text\n";

			return 1;
		}
	}
	else
	{
		$text = "DBG".$level."> ".$text;
	}

	if($level <= $config::hash{'debug'}{'value'})
	{
		open(FILE, ">>$main::log_file");
		print FILE "$text\n";
		close(FILE);
		if($config::hash{LOG_STDOUT}{value})
		{
			print "$text\n";
		}
	}
	if($level == 0 && $config::hash{ERROR_NOTIFY}{value})
	{
		&show_dialog("namefix.pl ERROR", "$text");
	}
	return;
}

sub clog
{
	open(FILE, ">$main::log_file");
	close(FILE);
}

#--------------------------------------------------------------------------------------------------------------
# save_file
#--------------------------------------------------------------------------------------------------------------

sub get_home
{
	my $home;
	$home = $ENV{USERPROFILE}	if $^O eq 'MSWin32';
	$home = $ENV{HOME}		if defined $ENV{HOME};

	$home = $ENV{TMP};	# surely the os has a tmp if nothing else

	$home =~ s/\\/\//g;

	if(!-d "$home/.namefix.pl")
	{
		mkdir("$home/.namefix.pl", 0755) or &main::quit("Cannot mkdir :$home/.namefix.pl $!\n");
	}
	return $home;
}

sub null_file
{
        my $file = shift;

        open(FILE, ">$file") or &main::quit("ERROR: sub null_file, Couldnt open $file to write to. $!");
        close(FILE);
}

sub save_file
{
        my $file	= shift;
        my $string	= shift;

        &main::quit("save_file \$file is undef")	if ! defined $file;
        &main::quit("save_file \$string is undef")	if ! defined $string;

        $string =~ s/^\n//g;		# no blank line @ start of file
        $string =~ s/\n\n+/\n/g;	# no blank lines in file

        open(FILE, ">$file") or &main::quit("ERROR: sub save_file, Couldnt open $file to write to. $!");
        print FILE $string;
        close(FILE);
}

sub file_append
{
	my $file	= shift;
	my $string	= shift;

	open(FILE, ">>$file") or &main::quit("ERROR: Couldnt open $file to append to. $!");
        print FILE $string;
        close(FILE);
}

#--------------------------------------------------------------------------------------------------------------
# read file
#--------------------------------------------------------------------------------------------------------------

sub readf
{
        my $file = shift;

        if(!-f $file)
        {
		print "misc::readf WARNING: file '$file' not found\n";
		return ();
        }

        open(FILE, "$file") or &main::quit("ERROR: Couldnt open $file to read.\n");
        my @file = <FILE>;
        close(FILE);

        # clean file of empty lines
        $file =~ s/^\n//g;
        $file =~ s/\n\n+/\n/g;

        return @file;
}

#--------------------------------------------------------------------------------------------------------------
# read file
#--------------------------------------------------------------------------------------------------------------

sub readf_clean
{
        my $file = shift;

        open(FILE, "$file") or &main::quit("ERROR: Couldnt open $file to read.\n");
        my @file = <FILE>;
        close(FILE);

	my @tmp;
        for my $l(@file)
        {
		# clean file of empty lines
		$l =~ s/^\n+//g;
		$l =~ s/\n+//g;
		$l =~ s/\s+#.*?\n//g;

		next if $l eq '';

		push @tmp, $l;
	}
        return sort {lc $a cmp lc $b} @tmp;
}

#--------------------------------------------------------------------------------------------------------------
# read and sort file
#--------------------------------------------------------------------------------------------------------------

sub readsf
{
        my $file = shift;

        open(FILE, "$file") or &main::quit("ERROR: Couldnt open $file to read.\n");
        my @file = <FILE>;
        close(FILE);

        # clean file of empty lines
        $file = join('', sort @file);
        $file =~ s/^\n//g;
        $file =~ s/\n\n+/\n/g;
        @file = split(/\n+/, $file);

        return @file;
}

#--------------------------------------------------------------------------------------------------------------
# read, sort and join file
#--------------------------------------------------------------------------------------------------------------

sub readsjf
{
	my $file = shift;
        open(FILE, "$file") or &main::quit("ERROR: Couldnt open $file to read.\n");
        my @file = <FILE>;
        close(FILE);
        $file = join('', sort @file);
        $file =~ s/^\n//g;
        $file =~ s/\n\n+/\n/g;

        return $file;
}

#--------------------------------------------------------------------------------------------------------------
# read and join file
#--------------------------------------------------------------------------------------------------------------

sub readjf
{
        my $file = shift;

        open(FILE, "$file") or &main::quit("ERROR: Couldnt open $file to read.\n");
        my @file = <FILE>;
        close(FILE);
        $file = join('', @file);
        $file =~ s/^\n//g;
        $file =~ s/\n\n+/\n/g;

        return $file;
}

#--------------------------------------------------------------------------------------------------------------
# clear options
#--------------------------------------------------------------------------------------------------------------

sub clr_no_save
{
	# clear options that are never saved

        $config::replace		= 0;
        $config::INS_START		= 0;
        $config::end_a			= 0;
	$config::ins_str_old         	= '';
        $config::ins_str         	= '';
        $config::ins_front_str		= '';
        $config::ins_end_str		= '';

	$config::id3_gen_str 		= 'Metal';
	$config::id3_art_str		= '';
	$config::id3_alb_str		= '';
	$config::id3_com_str		= '';
	$config::id3_year_str 		= '';

	$config::AUDIO_SET_ARTIST	= 0;
	$config::AUDIO_SET_ALBUM	= 0;
	$config::AUDIO_SET_COMMENT	= 0;
	$config::AUDIO_SET_GENRE 	= 0;
        $config::AUDIO_SET_YEAR 	= 0;
	$config::RM_AUDIO_TAGS		= 0;
}

#--------------------------------------------------------------------------------------------------------------
# Escape strings for use in regexp - wrote my own cos uri is fucked.
#--------------------------------------------------------------------------------------------------------------

# TODO remove
sub escape_string
{
	my $s = shift;
	return quotemeta $s;
}

sub is_in_array
{
	my $string	= shift;
	my $array_ref	= shift;

	return 1 if grep { $_ eq $string} @$array_ref;

	return 0;
}



1;