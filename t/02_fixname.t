#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 4;
use File::Copy;
use FindBin qw($Bin);

sub quit
{
	my $string = shift;
	die $string;
}

use lib "$Bin/../libs";

use config;
use fixname;


# unscene
$config::hash{unscene}{value} = 1;
my $file = "Hello - s03e11 - Today Tonight.avi";
is( &fixname::fn_unscene($file), 'Hello - 03x11 - Today Tonight.avi',  'fn_unscene test');

# scene
$config::hash{scene}{value} = 1;
$file = "Hello - 03x11 - Today Tonight.avi";
is( &fixname::fn_scene($file), 'Hello - S03E11 - Today Tonight.avi',  'fn_scene test');


# fn_spaces
$config::hash{spaces}{value} = 1;
$config::hash{space_character}{value} = ' ';
$file = "Hello_-_03x11_-_Today_Tonight.avi";
is( &fixname::fn_spaces(0, $file), 'Hello - 03x11 - Today Tonight.avi',  'fn_spaces test');

# fn_sp_char
$config::hash{sp_char}{value} = 1;
$file = 'Hello - 03x11 - (Today Tonight).avi';
is( &fixname::fn_sp_char($file), 'Hello - 03x11 - Today Tonight.avi',  'fn_sp_char test');


exit;
