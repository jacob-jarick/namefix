#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 4;
use FindBin qw($Bin);

use lib "$Bin/../libs";

use config;
use fixname;

# Set CLI mode to avoid GUI dependencies
$globals::CLI = 1;

#=============================================================================
# Misc Tab Functions
# Corresponds to CLI --help-misc options
#=============================================================================

# fn_intr_char (--int, -i) - international characters
&config::set_value('intr_char', 1);
my $file = 'Café München.avi';
is( &fixname::fn_intr_char(1, $file), 'Cafe Muenchen.avi',  'fn_intr_char test - international characters');

# fn_uc_all (--uc, -U) - uppercase all (DOS legacy)
&config::set_value('uc_all', 1);
$file = 'hello world.avi';
is( &fixname::fn_uc_all($file), 'HELLO WORLD.AVI',  'fn_uc_all test (DOS legacy - includes extension)');

# fn_lc_all (--lc, -L) - lowercase all
&config::set_value('lc_all', 1);
$file = 'HELLO WORLD.AVI';
is( &fixname::fn_lc_all($file), 'hello world.avi',  'fn_lc_all test');

# File extension recognition for non-media files
ok( !('test.txt' =~ /\.($config::hash{file_ext_2_proc}{value})$/i), 'TXT extension properly excluded from processing' );

# TODO: Add tests for other misc functions:
# fn_rm_nc (--rm-nc, --rmc) - remove nasty characters
# fn_rm_digits (--rm-starting-digits, --rsd) - remove starting digits  
# fn_digits (--rm-all-digits, --rad) - remove all digits
# fn_pad_dash (--pad-hyphen, -H, --ph) - pad hyphens
# fn_pad_digits (--pad-num, -N, --pn) - pad numbers
# fn_pad_digits_w_zero (--pad-num-w0, -0, --p0) - pad with zeros
# fn_pad_nnnn_wx (--pad-nnnn-wx, --px) - pad season/episode

exit;