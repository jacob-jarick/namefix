#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;
use FindBin qw($Bin);

sub quit
{
	my $string = shift;
	die $string;
}

use lib "$Bin/../libs";

use config;
use jpegexif;

# Set CLI mode to avoid GUI dependencies
$config::CLI = 1;

#=============================================================================
# EXIF Data Functions
# Corresponds to CLI --help-exif and --exif-* options  
#=============================================================================

# Test that EXIF module loads
ok( defined &jpegexif::is_exif_available, 'jpegexif module loaded successfully' );

# Test JPEG file recognition
ok( 'test.jpg' =~ /\.($config::hash{file_ext_2_proc}{value})$/i, 'JPEG extension recognized for EXIF processing' );

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