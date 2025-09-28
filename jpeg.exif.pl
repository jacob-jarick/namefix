#!/usr/bin/perl

# jpeg.exif.pl - test script to remove EXIF data from JPEG files
# once tested and stable, this functionality may be integrated into namefix.pl

use strict;
use warnings;
use Getopt::Long;
use File::Copy;
use File::Basename;

# Add libs directory to path
use FindBin;
use lib "$FindBin::Bin/libs";

# Use our EXIF module
use jpegexif;

# Check if EXIF module is available
unless (is_exif_available()) 
{
    print "Error: EXIF functionality not available\n";
    print get_exif_error() . "\n";
    exit 1;
}

# Command line options
my $help = 0;
my $rmexif = 0;  # Whether to actually apply changes or just preview

#=====================================================================================
# Main Program
#=====================================================================================

# Parse command line arguments
GetOptions
(
    'help|h'    => \$help,
    'rmexif|r'   => \$rmexif,
) 
or die "Error parsing command line options. Use --help for usage.\n";

show_help() if $help;

# Get target file from arguments
my $target = $ARGV[0] || die "Error: Please specify a JPEG file to process.\n";

# Validate target is a file
die "Error: '$target' is not a valid file.\n" if !-f $target;

# Print initial info
print "JPEG EXIF Removal Tool\n";
print "Target: $target\n";
print "Mode: " . ($rmexif ? "REMOVE" : "LIST") . "\n";

# Process the file
process_file($target);

print "\nProcessing complete.\n";

exit 0;

#=====================================================================================
# Core Functions
#=====================================================================================

sub process_file 
{
    my $filepath = shift;
    
    print "Processing: $filepath\n";
    
    # Check if file has EXIF data using our module
    if (!has_exif_data($filepath)) 
    {
        print "  No writable EXIF data found in: $filepath\n";
        return;
    }
    
    print "  Found EXIF data in: $filepath\n";
    
    # if we arent removing exif, list tags and return
    if (!$rmexif) 
    {
        print "  [PREVIEW] Would remove EXIF data from: $filepath\n";
        
        # Get and display EXIF tags using our module
        my $tags_found = list_exif_tags($filepath);
        
        for my $tag (sort keys %$tags_found)
        {
            my $value = $tags_found->{$tag} // '';
            print "    $tag: $value\n";
        }

        return;
    }
    
    # Remove EXIF data using our module
    my $result = remove_exif_data($filepath);
    
    if ($result) 
    {
        print "  Removed EXIF data from: $filepath\n";
    } 
    else 
    {
        warn "  Error removing EXIF data from $filepath: " . get_last_error() . "\n";
    }
}

#=====================================================================================
# Help Functions  
#=====================================================================================

sub show_help 
{
    print "
USAGE:
    perl jpeg.exif.pl [options] <jpeg_file>
    
ARGUMENTS:
    <jpeg_file>         JPEG file to process (required)
    
OPTIONS:
    -h, --help          Show this help message
    -r, --rmexif        Remove EXIF data instead of just listing it
";    
}




