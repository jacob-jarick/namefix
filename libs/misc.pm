# home to all my small misc functions.
package misc;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;
use File::Spec::Functions;
use Cwd qw(realpath);
use File::stat;

sub ci_sort
{
	my @sortme2 = sort { lc($a) cmp lc($b) } @_;
	return @sortme2;
}

# plog - print log

# Notes:
# do not have plog call subroutines in that will call plog - avoids recursion errors

sub plog
{
	my $level		= shift;
	my $text		= shift;

	my $date_time	= localtime();
	my $subroutine	= 'main'; # get caller - handle packed executables better
	my $depth		= 1;

	# Limit depth to avoid infinite loops
	while ($depth < 10) 
	{ 
		my $caller_sub = (caller($depth))[3];
		last if !defined $caller_sub;
		# Skip PAR packer and eval contexts
		if 
		(
			$caller_sub ne '(eval)' && 
		    $caller_sub !~ /^PAR::/ && 
		    $caller_sub !~ /^___par_pl::/ &&
		    $caller_sub !~ /::BEGIN$/
		) 
		{
			$subroutine = $caller_sub;
			last;
		}
		$depth++;
	}

	# Add level information to message
	my $level_text;
	if ($level == 0) 
	{
		$level_text = "ERROR";
	} 
	elsif ($level == 1) 
	{
		$level_text = "WARN";
	} 
	elsif ($level == 2) 
	{
		$level_text = "INFO";
	} 
	else 
	{
		my $debug_level = $level - 2;
		$level_text = "DEBUG($debug_level)";
	}

	$text = "[$date_time] [$subroutine] [$level_text] $text";

	# CLI mode

	if($globals::CLI)
	{
		if($level <= $config::hash{debug}{value})
		{
			open(FILE, ">>$main::log_file");
			print FILE "$text\n";
			close(FILE);

			exit if $level == 0 && $config::hash{exit_on_error}{value} == 1;

			return 1;
		}
	}

	# GUI mode
	# everything below is GUI mode

	if($level <= $config::hash{debug}{value})
	{
		open(FILE, ">>$main::log_file");
		print FILE "$text\n";
		close(FILE);
		
		# Add to GUI log with styling if not in CLI mode
		if(!$globals::CLI) 
        {
			&log::add($level, "$text\n");
		}
		
		if($config::hash{log_stdout}{value})
		{
			print "$text\n";
		}
	}

	if($level == 0 && $config::hash{error_notify}{value})
	{
		# Add error to GUI log with styling if not in CLI mode
		if(!$globals::CLI) 
        {
			&log::add($level, "$text\n");
		}
		&show_dialog("namefix.pl ERROR", "$text");
	}

	exit if $level == 0 && $config::hash{exit_on_error}{value} == 1;

	return 1;
}

#--------------------------------------------------------------------------------------------------------------
# save_file
#--------------------------------------------------------------------------------------------------------------

sub get_home
{
	my $home = undef;
	$home = $ENV{HOME}		    if defined $ENV{HOME} && lc $^O ne lc 'MSWin32';
	$home = $ENV{USERPROFILE}	if lc $^O eq lc 'MSWin32';


	$home = $ENV{TMP}		    if ! defined $home; # surely the os has a tmp if nothing else
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
    
    if (!open(FILE, ">$file")) 
	{
        &misc::plog(0, "sub null_file, Couldn't open $file to write to. $!");
        return 0;
    }

    close(FILE);
    return 1;
}

sub save_file
{
    my $file	= shift;
    my $string	= shift;

    &main::quit("save_file \$file is undef")	if ! defined $file;
    &main::quit("save_file \$string is undef")	if ! defined $string;

    $string =~ s/^\n//g;		# no blank line @ start of file
    $string =~ s/\n\n+/\n/g;	# no blank lines in file

    open(FILE, ">$file") or &main::quit("ERROR: sub save_file, Couldn't open $file to write to. $!");
    print FILE $string;
    close(FILE);
}

sub file_append
{
	my $file	= shift;
	my $string	= shift;

	if (!open(FILE, ">>$file")) 
	{
        &misc::plog(0, "Couldn't open $file to append to. $!");
        return 0;
    }

    print FILE $string;
    close(FILE);

    return 1;
}

#--------------------------------------------------------------------------------------------------------------
# read file
#--------------------------------------------------------------------------------------------------------------

sub readf
{
	# get caller
	my ($package, $filename, $line, $subroutine) = caller(1);

    my $file = shift;

    if(!-f $file)
    {
		&misc::plog(0, "$subroutine called from $filename line $line: file '$file' not found");
        return ();
    }

    open(FILE, "$file") or &main::quit("ERROR: Couldn't open $file to read.\n");
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

    open(FILE, "$file") or &main::quit("ERROR: Couldn't open $file to read.\n");
    my @file = <FILE>;
    close(FILE);

	my @tmp;
    for my $l(@file)
    {
		# clean file of empty lines
		$l =~ s/\n+//g;
		$l =~ s/\s*#.*?$//g;

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

    open(FILE, "$file") or &main::quit("ERROR: Couldn't open $file to read.\n");
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

    open(FILE, "$file") or &main::quit("ERROR: Couldn't open $file to read.\n");
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

    open(FILE, "$file") or &main::quit("ERROR: Couldn't open $file to read.\n");
    my @file = <FILE>;
    close(FILE);

    $file = join('', @file);
    $file =~ s/^\n//g;
    $file =~ s/\n\n+/\n/g;

    return $file;
}

#--------------------------------------------------------------------------------------------------------------
# Escape strings for use in regexp - wrote my own cos uri is fucked.
#--------------------------------------------------------------------------------------------------------------

sub is_in_array
{
	my $string		= shift;
	my $array_ref	= shift;

	return 1 if grep { $_ eq $string} @$array_ref;

	return 0;
}

# my ($d, $f, $p) = get_file_info($file);
sub get_file_info
{
	my $file	= shift;

	&main::quit("get_file_info: \$file is undef") if ! defined $file;
	&main::quit("get_file_info: \$file '$file' is not a dir or file") if !-f $file && !-d $file;

	my $file_path	= &get_file_path($file);
	my $file_name	= &get_file_name($file_path);
	my $file_dir	= &get_file_parent_dir($file_path);

	return ($file_dir, $file_name, $file_path);
}

sub get_file_path
{
	my $file	= shift;

	&main::quit("get_file_path: \$file is undef") if ! defined $file;
	&main::quit("get_file_path: \$file '$file' is not a dir or file") if !-f $file && !-d $file;

	my $file_path	= File::Spec->rel2abs($file);
	$file_path	=~ s/\\/\//g;

	return $file_path;
}

sub get_file_parent_dir
{
	my $file_path	= shift;
	$file_path		= &get_file_path($file_path);
	my @tmp			= split(/\//, $file_path);
	my $file_name	= splice @tmp , $#tmp, 1;
	my $file_dir	= join('/', @tmp);

	return $file_dir;
}

sub get_file_name
{
	my $file_path	= shift;
	$file_path		= &get_file_path($file_path);
	my @tmp			= split(/\//, $file_path);

	return $tmp[$#tmp];
}

sub get_file_ext
{
	my $file_path	= shift;

	return undef if !-f $file_path;

	$file_path		= &get_file_path($file_path);
	my @tmp			= split(/\//, $file_path);
	my $file_name	= splice @tmp , $#tmp, 1;

	if ($file_name =~ /^(.+)\.(.+?)$/)
	{
		return ($1, $2);
	}

	return undef;
}


1;
