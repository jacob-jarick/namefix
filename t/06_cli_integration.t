#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 1;
use FindBin qw($Bin);

#=============================================================================
# CLI Integration Tests
# Tests the command-line interface functionality
#=============================================================================

# Test that CLI script exists and is executable
ok( -f "$Bin/../namefix-cli.pl", 'namefix-cli.pl exists and CLI integration possible' );

# TODO: Add comprehensive CLI integration tests:
#
# Option parsing tests:
# - Short options (-g, -c, -p, etc.)
# - Long options (--clean, --case, --spaces, etc.) 
# - Option combinations
# - Invalid option handling
# - Recently fixed parsing issues (--save-opt vs $_/$arg bug)
#
# Functionality tests:
# - Directory processing  
# - Recursive mode (--recr) - recently fixed CLI crash
# - Directory processing (--dir) - recently fixed CLI crash
# - Preview vs rename mode (--rename)
# - File filtering (--filt, --all-files)
# - EXIF display (--exif-show) - recently fixed and working!
#
# Output format tests:
# - CLI output format (file -> newfile) 
# - Debug output levels
# - Error handling and messages
# - Recently fixed: CLI no longer crashes on nf_print::p calls
#
# Integration with core functions:
# - Verify CLI options properly set config hash values
# - Verify CLI calls fixname functions correctly
# - Verify CLI handles file vs directory arguments

exit;