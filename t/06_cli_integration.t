#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;
use FindBin qw($Bin);

#=============================================================================
# CLI Integration Tests
# Tests the command-line interface functionality
#=============================================================================

# Test that CLI script exists and is executable
ok( -f "$Bin/../namefix-cli.pl", 'namefix-cli.pl exists and CLI integration possible' );

# perl namefix-cli.pl --debug=0 --exif-show testdata/images/DSCN0021_original.jpg
{
    my $output = qx{cd "$Bin/.." && perl namefix-cli.pl --debug=0 --exif-show testdata/images/DSCN0021_original.jpg 2>&1};
    like( $output, qr/=== EXIF Data for/, '--debug=0 still shows EXIF data' );
}



exit;