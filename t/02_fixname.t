#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 2;
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
my $file = "Hello - 03x11 - Today Tonight.avi";
is( &fixname::fn_scene($file), 'Hello - S03E11 - Today Tonight.avi',  'fn_scene test');


exit;
