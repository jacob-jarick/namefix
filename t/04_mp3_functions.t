#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 1;
use FindBin qw($Bin);

sub quit
{
	my $string = shift;
	die $string;
}

use lib "$Bin/../libs";

use config;
use mp3;

# Set CLI mode to avoid GUI dependencies
$config::CLI = 1;

#=============================================================================
# MP3/ID3 Tag Functions  
# Corresponds to CLI --help-mp3 options
#=============================================================================

# Test that MP3 module loads and basic functionality works
ok( 'test.mp3' =~ /\.($config::hash{file_ext_2_proc}{value})$/i, 'MP3 extension recognized for ID3 processing' );

# TODO: Add comprehensive MP3/ID3 tests:
# mp3::get_tags() - read ID3 tags
# mp3::write_tags() - write ID3 tags  
# mp3::rm_tags() - remove ID3 tags
# mp3::guess_tags() - guess tags from filename
# 
# CLI options to test:
# --id3-guess - guess mp3 tags from filename
# --id3-overwrite - overwrite existing id3 tags
# --id3-rm-v1 - remove v1 id3 tags
# --id3-rm-v2 - remove v2 id3 tags
# --id3-art=STRING - Set id3 artist tag
# --id3-tit=STRING - Set id3 title tag  
# --id3-tra=STRING - Set id3 track tag
# --id3-alb=STRING - Set id3 album tag
# --id3-yer=STRING - Set id3 year tag
# --id3-com=STRING - Set id3 comment tag

exit;