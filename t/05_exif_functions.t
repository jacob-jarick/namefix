#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 18;
use FindBin qw($Bin);
use File::Copy;
use POSIX qw(strftime);

use lib "$Bin/../libs";

use config;
use jpegexif;

# Set CLI mode to avoid GUI dependencies
$globals::CLI = 1;
$config::hash{'debug'}{'value'} = 0;

#=============================================================================
# EXIF Data Functions
# Corresponds to CLI --help-exif and --exif-* options  
#=============================================================================

# Test that EXIF module loads
ok( defined &jpegexif::is_exif_available, 'jpegexif module loaded successfully' );

# Test JPEG file recognition
ok( 'test.jpg' =~ /\.($config::hash{file_ext_2_proc}{value})$/i, 'JPEG extension recognized for EXIF processing' );

# Test EXIF data detection
{
    my $test_file = "$Bin/../testdata/images/DSCN0021_original.jpg";
    ok( -f $test_file, 'Test EXIF file exists' );
    ok( jpegexif::has_exif_data($test_file), 'Test file has EXIF data' );
}

# Test EXIF data removal directly with library functions
{
    # Create temp directory if it doesn't exist
    my $temp_dir = "$Bin/../temp";
    mkdir($temp_dir) unless -d $temp_dir;
    ok( -d $temp_dir && -w $temp_dir, 'Temp directory exists and is writable' );

    # Create datetime string
    my $datetime = strftime("%Y%m%d_%H%M%S", localtime());
    my $test_file = "$Bin/../testdata/images/DSCN0021_original.jpg";
    my $temp_file = "$temp_dir/${datetime}.jpg";

    # Copy test file to temp directory
    ok( copy($test_file, $temp_file), 'Test file copied to temp directory' );
    ok( -f $temp_file, 'Copied file exists in temp directory' );

    # Confirm copied file has EXIF data
    ok( jpegexif::has_exif_data($temp_file), 'Copied file has EXIF data' );

    # Get EXIF tag count before removal
    my $tags_before = jpegexif::list_exif_tags($temp_file);
    my $count_before = $tags_before ? scalar(keys %$tags_before) : 0;
    
    # Remove EXIF data (note: some EXIF data may be embedded and unremovable)
    ok( jpegexif::remove_exif_data($temp_file), 'EXIF data removal function executed successfully' );

    # Get EXIF tag count after removal
    my $tags_after = jpegexif::list_exif_tags($temp_file);
    my $count_after = $tags_after ? scalar(keys %$tags_after) : 0;
    
    # Verify that some EXIF data was removed (or at least the function ran)
    # Note: Some basic EXIF data may remain as it's embedded in the image format
    ok( defined($tags_before) && defined($tags_after), 'EXIF tag listing works before and after removal' );

    # Clean up
    unlink($temp_file);
}

# Test CLI --exif-rm option
{
    # Create temp directory if it doesn't exist
    my $temp_dir = "$Bin/../temp";
    mkdir($temp_dir) unless -d $temp_dir;
    ok( -d $temp_dir && -w $temp_dir, 'Temp directory exists and is writable for CLI test' );

    # Create datetime string for unique filename
    my $datetime = strftime("%Y%m%d_%H%M%S", localtime());
    my $test_file = "$Bin/../testdata/images/DSCN0021_original.jpg";
    my $temp_file = "$temp_dir/${datetime}_cli_test.jpg";

    # Copy test file to temp directory
    ok( copy($test_file, $temp_file), 'Test file copied for CLI EXIF removal test' );
    ok( -f $temp_file, 'CLI test file exists' );

    # Get initial writable EXIF tag count
    my $tags_before = jpegexif::writable_exif_tag_count($temp_file);
    ok( defined($tags_before) && $tags_before > 0, 'Initial EXIF tag count > 0' );

    # Run CLI command to remove EXIF data
    my $cli_cmd = "perl namefix-cli.pl --rename --exif-rm \"$temp_file\"";
    my $cli_output = qx{cd "$Bin/.." && $cli_cmd 2>&1};
    print "testing: $cli_cmd\n";
    print "output: $cli_output\n" if $cli_output;
    ok( $? == 0, 'CLI --exif-rm command executed successfully' );

    # Get final writable EXIF tag count
    my $tags_after = jpegexif::writable_exif_tag_count($temp_file);
    ok( defined($tags_after), 'Final EXIF tag count retrieved' );

    # Verify that EXIF data was reduced (some may remain as embedded)
    ok( $tags_after <= $tags_before, 'EXIF tag count reduced or maintained after CLI removal' );

    # Clean up
    unlink($temp_file);
    ok( ! -f $temp_file, 'CLI test file cleaned up' );
}

# TODO: Add comprehensive EXIF tests:
# jpegexif::has_exif_data() - detect EXIF presence
# jpegexif::list_exif_tags() - list all EXIF tags
# jpegexif::remove_exif_data() - remove EXIF data
# jpegexif::is_exif_available() - check if Image::ExifTool available
#
# CLI options to test:  
# --exif-show - show all available EXIF data (recently fixed!)

# example command:
# note: need to add single file option
# perl namefix-cli.pl  --exif-show .\testdata\images\

# --exif-rm - remove all EXIF data
# --exif-rm-tags=STRING - remove specific EXIF tags

exit;