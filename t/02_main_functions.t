#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 5;
use FindBin qw($Bin);

use lib "$Bin/../libs";

use config;
use fixname;

# Set CLI mode to avoid GUI dependencies
$globals::CLI = 1;

#=============================================================================
# Main Tab Functions - Core namefix functionality 
# Corresponds to CLI --help-short (most used options)
#=============================================================================

# fn_cleanup_general (--clean, -g)
# TODO: Need to verify function signature

# fn_case (--case, -c) 
# TODO: Need to verify function signature

# fn_spaces (--spaces, -p)
&config::reset_config();
$config::hash{spaces}{value} = 1;
$config::hash{space_character}{value} = ' ';
my $file = "Hello_-_03x11_-_Today_Tonight.avi";
my $expected = 'Hello - 03x11 - Today Tonight.avi';
is( &fixname::fn_spaces(0, $file), $expected,  'fn_spaces test (underscores to spaces)');

# fn_dot2space (--dots, -o)
&config::reset_config();
$config::hash{dot2space}{value} = 1;
$file = 'Hello.World.Episode.01.avi';
$expected = 'Hello World Episode 01.avi';
is( &fixname::fn_dot2space(1, $file, $file), $expected,  'fn_dot2space test');

# fn_sp_char (remove special characters like parentheses)
&config::reset_config();
$config::hash{sp_char}{value} = 1;
$file = 'Hello - 03x11 - (Today Tonight).avi';
$expected = 'Hello - 03x11 - Today Tonight.avi';
is( &fixname::fn_sp_char($file), $expected,  'fn_sp_char test (remove parentheses)');

# Scene/Unscene functions (--scene/--unscene, -s/-u)
# fn_unscene
&config::reset_config();
$config::hash{unscene}{value} = 1;
$file = "Hello - s03e11 - Today Tonight.avi";
$expected = 'Hello - 03x11 - Today Tonight.avi';
is( &fixname::fn_unscene($file), $expected,  'fn_unscene test (s03e11 to 03x11)');

# fn_scene
&config::reset_config();
$config::hash{scene}{value} = 1;  # Set to 0 to enable processing
$file = "Hello - 03x11 - Today Tonight.avi";
$expected = 'Hello - S03E11 - Today Tonight.avi';
is( &fixname::fn_scene($file), $expected,  'fn_scene test (03x11 to S03E11)');

exit;