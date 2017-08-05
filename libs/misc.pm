# home to all my small misc functions.
package misc;
require Exporter;
@ISA = qw(Exporter);



use strict;
use warnings;

my @output = ();

sub ci_sort
{
	&plog(3, "sub ci_sort:");
	my @sortme2 = sort { lc($a) cmp lc($b) } @_;
	return @sortme2;
}

# plog - print log

# Notes:
# Since i will be logging all subs (excluding plog itself, plug cannot call any namefix subs (recursion errors which locked linux on my system)

sub plog
{
	my $level = shift;
	my $text = shift;

	if($main::CLI == 0) # gui mode
	{
		push @output, "$text\n";
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
		if($main::CLI)
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
	if($^O eq "MSWin32")
	{
		return $ENV{"USERPROFILE"};
	}
	return $ENV{"HOME"},
}

sub null_file
{
        my $file = shift;

	&plog(3, "sub null_file: \"$file\"");
        open(FILE, ">$file") or die "ERROR: sub null_file, Couldnt open $file to write to. $!";
        close(FILE);
}

sub save_file
{
        my $file = shift;
        my $t = shift;

	&plog(3, "sub save_file: \"$file\"");
#	print "savefile: $file : $t\n";
        $t =~ s/^\n//g;		# no blank line @ start of file
        $t =~ s/\n\n+/\n/g;	# no blank lines in file
        open(FILE, ">$file") or die "ERROR: sub save_file, Couldnt open $file to write to. $!";
        print FILE $t;
        close(FILE);
}

sub file_append
{
	my $file = shift;
	my $string = shift;

	&plog(3, "sub file_append: \"$file\"");

	open(FILE, ">>$file") or die "ERROR: Couldnt open $file to append to. $!";
        print FILE $string;
        close(FILE);
}

#--------------------------------------------------------------------------------------------------------------
# read file
#--------------------------------------------------------------------------------------------------------------

sub readf
{
        my $file = $_[0];

	&plog(3, "sub readf: \"$file\"");

        open(FILE, "$file") or die("ERROR: Couldnt open $file to read.\n");
        my @file = <FILE>;
        close(FILE);

        # clean file of empty lines
        $file =~ s/^\n//g;
        $file =~ s/\n\n+/\n/g;

        return @file;
}

#--------------------------------------------------------------------------------------------------------------
# read and sort file
#--------------------------------------------------------------------------------------------------------------

sub readsf
{
        my $file = $_[0];

	&plog(3, "sub readsf: \"$file\"");

        open(FILE, "$file") or die("ERROR: Couldnt open $file to read.\n");
        my @file = <FILE>;
        close(FILE);

        # clean file of empty lines
        $file = join('', sort @file);
        $file =~ s/^\n//g;
        $file =~ s/\n\n+/\n/g;
        @file = split('\n+', $file);

        return @file;
}

#--------------------------------------------------------------------------------------------------------------
# read, sort and join file
#--------------------------------------------------------------------------------------------------------------

sub readsjf
{
        my $file = $_[0];
	&plog(3, "sub readsjf: \"$file\"");
        open(FILE, "$file") or die("ERROR: Couldnt open $file to read.\n");
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
        my $file = $_[0];
	&plog(3, "sub readjf: \"$file\"");

        open(FILE, "$file") or die("ERROR: Couldnt open $file to read.\n");
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
	&plog(3, "sub clr_no_save ");
	# clear options that are never saved

        $main::replace		= 0;
	$main::rpwold         	= "";
        $main::rpwnew         	= "";
        $main::front_a		= 0;
        $main::faw            	= "";
        $main::end_a		= 0;
        $main::eaw            	= "";

	$main::id3_art_str	= "";
	$main::id3_alb_str	= "";
	$main::id3_com_str	= "";
	$main::id3_gen_str 	= "Metal";
	$main::id3_year_str 	= "";

	$main::id3_art_set	= 0;
	$main::id3_alb_set	= 0;
	$main::id3_com_set	= 0;
	$main::id3_gen_set 	= 0;
        $main::id3_year_set 	= 0;

	$main::id3v1_rm		= 0;
	$main::id3v2_rm		= 0;
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
	my $string = shift;
	my $array_ref = shift;

	return 1 if grep { $_ eq $string} @$array_ref;

	return 0;
}

1;