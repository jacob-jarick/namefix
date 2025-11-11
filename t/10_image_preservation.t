#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 14;
use FindBin qw($Bin);
use File::Copy;
use File::Path qw(make_path);
use Digest::MD5 qw(md5_hex);

use lib "$Bin/../libs";

use config;
use globals;
use mp3;

# Set CLI mode to avoid GUI dependencies  
$globals::CLI = 1;

# Initialize globals that mp3 module needs
globals::init_globals();

# Test source file path - DO NOT MODIFY THIS FILE, ALWAYS COPY TO TEMP
my $source_mp3 = "$Bin/../testdata/AI mp3s/2 - Love in the Forest.mp3";
my $temp_dir = "$Bin/../temp";

#=============================================================================
# Embedded Image Preservation Test Suite
# Tests that embedded album art is preserved during tag modifications
#=============================================================================

# Verify test MP3 file exists
ok( -f $source_mp3, 'Test MP3 file with embedded image exists' );

# Create temp directory
make_path($temp_dir) unless -d $temp_dir;
ok( -d $temp_dir && -w $temp_dir, 'Temp directory exists and is writable' );

# Helper function to extract embedded image data and hash
sub get_image_hash {
    my $filepath = shift;
    
    use MP3::Tag;
    my $mp3 = MP3::Tag->new($filepath);
    $mp3->get_tags();
    
    return undef unless exists $mp3->{ID3v2};
    
    my $id3v2 = $mp3->{ID3v2};
    my ($info, $pic_data) = $id3v2->get_frame('APIC');
    
    $mp3->close();
    
    return undef unless defined $pic_data;
    return md5_hex($pic_data);
}

# Get original image hash
my $original_hash = get_image_hash($source_mp3);
ok( defined $original_hash, 'Original MP3 has embedded image' );
diag( "Original image hash: $original_hash" );

#=============================================================================
# Test 1: Single Tag Modification
#=============================================================================

{
    my $test_file = "$temp_dir/test_image_single_tag.mp3";
    copy($source_mp3, $test_file);
    
    # Modify artist tag
    my $cmd = qq{perl namefix-cli.pl --id3-art="New Artist" --id3-overwrite --process "$test_file"};
    my $output = qx($cmd 2>&1);
    my $exit_code = $? >> 8;
    
    ok( $exit_code == 0, 'Single tag modification executed successfully' );
    
    # Verify image is preserved
    my $after_hash = get_image_hash($test_file);
    ok( defined $after_hash, 'Embedded image still present after single tag modification' );
    is( $after_hash, $original_hash, 'Embedded image unchanged after single tag modification' );
    
    unlink($test_file);
}

#=============================================================================
# Test 2: Multiple Tag Modifications
#=============================================================================

{
    my $test_file = "$temp_dir/test_image_multiple_tags.mp3";
    copy($source_mp3, $test_file);
    
    # Modify multiple tags
    my $cmd = qq{perl namefix-cli.pl --id3-art="Multi Artist" --id3-tit="Multi Title" --id3-alb="Multi Album" --id3-tra="05" --id3-yer="2024" --id3-com="Test" --id3-gen="Electronic" --id3-overwrite --process "$test_file"};
    my $output = qx($cmd 2>&1);
    my $exit_code = $? >> 8;
    
    ok( $exit_code == 0, 'Multiple tag modification executed successfully' );
    
    # Verify image is preserved
    my $after_hash = get_image_hash($test_file);
    ok( defined $after_hash, 'Embedded image still present after multiple tag modifications' );
    is( $after_hash, $original_hash, 'Embedded image unchanged after multiple tag modifications' );
    
    unlink($test_file);
}

#=============================================================================
# Test 3: Tag Guessing with Image Preservation
#=============================================================================

{
    my $test_file = "$temp_dir/Artist - Title.mp3";
    copy($source_mp3, $test_file);
    
    # Use tag guessing
    my $cmd = qq{perl namefix-cli.pl --id3-guess --id3-overwrite --process "$test_file"};
    my $output = qx($cmd 2>&1);
    my $exit_code = $? >> 8;
    
    ok( $exit_code == 0, 'Tag guessing executed successfully' );
    
    # Verify image is preserved
    my $after_hash = get_image_hash($test_file);
    ok( defined $after_hash, 'Embedded image still present after tag guessing' );
    is( $after_hash, $original_hash, 'Embedded image unchanged after tag guessing' );
    
    unlink($test_file);
}

#=============================================================================
# Test 4: Direct mp3::write_tags call
#=============================================================================

{
    my $test_file = "$temp_dir/test_image_direct_write.mp3";
    copy($source_mp3, $test_file);
    
    # Get current tags
    my $ref = mp3::get_tags($test_file);
    my %tags = %$ref;
    
    # Modify a tag
    $tags{artist} = 'Direct Write Artist';
    
    # Write tags directly
    mp3::write_tags($test_file, \%tags);
    
    # Verify image is preserved
    my $after_hash = get_image_hash($test_file);
    ok( defined $after_hash, 'Embedded image still present after direct write_tags call' );
    is( $after_hash, $original_hash, 'Embedded image unchanged after direct write_tags call' );
    
    unlink($test_file);
}

diag( "All tests passed - embedded images are preserved during tag modifications" );

exit;
