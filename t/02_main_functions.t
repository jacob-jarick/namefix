#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 6;
use FindBin qw($Bin);

sub quit
{
	my $string = shift;
	die $string;
}

use lib "$Bin/../libs";

use config;
use fixname;

# Set CLI mode to avoid GUI dependencies
$config::CLI = 1;

#=============================================================================
# Main Tab Functions - Core namefix functionality 
# Corresponds to CLI --help-short (most used options)
#=============================================================================

# fn_cleanup_general (--clean, -g)
# TODO: Need to verify function signature

# fn_case (--case, -c) 
# TODO: Need to verify function signature

# fn_spaces (--spaces, -p)
$config::hash{spaces}{value} = 1;
$config::hash{space_character}{value} = ' ';
my $file = "Hello_-_03x11_-_Today_Tonight.avi";
is( &fixname::fn_spaces(0, $file), 'Hello - 03x11 - Today Tonight.avi',  'fn_spaces test (underscores to spaces)');

# fn_dot2space (--dots, -o)
$config::hash{dot2space}{value} = 1;
$file = 'Hello.World.Episode.01.avi';
is( &fixname::fn_dot2space(1, $file, $file), 'Hello World Episode 01.avi',  'fn_dot2space test');

# fn_sp_char (remove special characters like parentheses)
$config::hash{sp_char}{value} = 1;
$file = 'Hello - 03x11 - (Today Tonight).avi';
is( &fixname::fn_sp_char($file), 'Hello - 03x11 - Today Tonight.avi',  'fn_sp_char test (remove parentheses)');

# Scene/Unscene functions (--scene/--unscene, -s/-u)
# fn_unscene
$config::hash{unscene}{value} = 1;
$file = "Hello - s03e11 - Today Tonight.avi";
is( &fixname::fn_unscene($file), 'Hello - 03x11 - Today Tonight.avi',  'fn_unscene test (s03e11 to 03x11)');

# fn_scene  
$config::hash{scene}{value} = 0;  # Set to 0 to enable processing
$file = "Hello - 03x11 - Today Tonight.avi";
is( &fixname::fn_scene($file), 'Hello - S03E11 - Today Tonight.avi',  'fn_scene test (03x11 to S03E11)');

#=============================================================================
# File Extension Recognition (core functionality)
#=============================================================================

# Test file extension processing logic
ok( 'test.mp3' =~ /\.($config::hash{file_ext_2_proc}{value})$/i, 'MP3 extension recognized' );

exit;