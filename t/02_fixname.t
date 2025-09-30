#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 1;
use FindBin qw($Bin);

#=============================================================================
# DEPRECATED: This file has been reorganized into focused test files
#=============================================================================

# This test file has been split into the following organized files:
# - 02_main_functions.t    - Core namefix functionality (--help-short)
# - 03_misc_functions.t    - Misc options (--help-misc) 
# - 04_mp3_functions.t     - MP3/ID3 tag processing (--help-mp3)
# - 05_exif_functions.t    - EXIF data processing (--help-exif)
# - 06_cli_integration.t   - CLI functionality and integration tests
# - 07_config_tests.t      - Configuration system tests
#
# This organization matches the CLI help structure for better maintainability.

# Placeholder test to ensure this file still runs
ok( 1, 'Test structure reorganized - see other 02-07 test files' );

exit;
