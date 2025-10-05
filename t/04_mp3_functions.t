#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 47;
use FindBin qw($Bin);
use File::Copy;
use File::Path qw(make_path remove_tree);

sub quit
{
	my $string = shift;
	die $string;
}

use lib "$Bin/../libs";

use config;
use globals;
use mp3;

# Set CLI mode to avoid GUI dependencies  
$globals::CLI = 1;

# Initialize globals that mp3 module needs
globals::init_globals();

# Test source file path
my $source_mp3 = "$Bin/../testdata/AI mp3s/suno - Love in the Forest.mp3";
my $temp_dir = "$Bin/../temp";

#=============================================================================
# MP3/ID3 Tag Functions Test Suite
# Tests CLI --help-mp3 options using real MP3 file manipulation
#=============================================================================

# Test that MP3 module loads and basic functionality works
ok( 'test.mp3' =~ /\.($config::hash{file_ext_2_proc}{value})$/i, 'MP3 extension recognized for ID3 processing' );

# Verify test MP3 file exists
ok( -f $source_mp3, 'Test MP3 file exists' );

# Create temp directory and copy test file
make_path($temp_dir) unless -d $temp_dir;
ok( -d $temp_dir && -w $temp_dir, 'Temp directory exists and is writable' );

my $test_mp3 = "$temp_dir/test_mp3_tags.mp3";
copy($source_mp3, $test_mp3) or die "Cannot copy test MP3: $!";
ok( -f $test_mp3, 'Test MP3 copied to temp directory' );

#=============================================================================
# CLI MP3 Tag Setting Tests
# Test each --id3-* option individually
#=============================================================================

# Test Artist Tag Setting
{
    my $test_file = "$temp_dir/test_artist.mp3";
    copy($source_mp3, $test_file);
    
    my $cmd = qq{perl namefix-cli.pl --id3-art="Test Artist" --id3-overwrite --process "$test_file"};
    my $output = qx($cmd 2>&1);
    my $exit_code = $? >> 8;
    
    ok( $exit_code == 0, 'CLI --id3-art command executed successfully' );
    like( $output, qr/Processing|would have|modified/, 'CLI artist tag processing output received' );
    
    # Verify tag was set by reading it back
    my $ref = mp3::get_tags($test_file);
    my %tags = %$ref;
    is( $tags{artist}, 'Test Artist', 'Artist tag correctly set via CLI' );
    
    unlink($test_file);
}

# Test Title Tag Setting  
{
    my $test_file = "$temp_dir/test_title.mp3";
    copy($source_mp3, $test_file);
    
    my $cmd = qq{perl namefix-cli.pl --id3-tit="Test Title" --id3-overwrite --process "$test_file"};
    my $output = qx($cmd 2>&1);
    my $exit_code = $? >> 8;
    
    ok( $exit_code == 0, 'CLI --id3-tit command executed successfully' );
    
    my $ref = mp3::get_tags($test_file);
    my %tags = %$ref;
    is( $tags{title}, 'Test Title', 'Title tag correctly set via CLI' );
    
    unlink($test_file);
}

# Test Album Tag Setting
{
    my $test_file = "$temp_dir/test_album.mp3";
    copy($source_mp3, $test_file);
    
    my $cmd = qq{perl namefix-cli.pl --id3-alb="Test Album" --id3-overwrite --process "$test_file"};
    my $output = qx($cmd 2>&1);
    my $exit_code = $? >> 8;
    
    ok( $exit_code == 0, 'CLI --id3-alb command executed successfully' );
    
    my $ref = mp3::get_tags($test_file);
    my %tags = %$ref;
    is( $tags{album}, 'Test Album', 'Album tag correctly set via CLI' );
    
    unlink($test_file);
}

# Test Track Tag Setting
{
    my $test_file = "$temp_dir/test_track.mp3";
    copy($source_mp3, $test_file);
    
    my $cmd = qq{perl namefix-cli.pl --id3-tra="05" --id3-overwrite --process "$test_file"};
    my $output = qx($cmd 2>&1);
    my $exit_code = $? >> 8;
    
    ok( $exit_code == 0, 'CLI --id3-tra command executed successfully' );
    
    my $ref = mp3::get_tags($test_file);
    my %tags = %$ref;
    is( $tags{track}, '05', 'Track tag correctly set via CLI' );
    
    unlink($test_file);
}

# Test Year Tag Setting
{
    my $test_file = "$temp_dir/test_year.mp3";
    copy($source_mp3, $test_file);
    
    my $cmd = qq{perl namefix-cli.pl --id3-yer="2025" --id3-overwrite --process "$test_file"};
    my $output = qx($cmd 2>&1);
    my $exit_code = $? >> 8;
    
    ok( $exit_code == 0, 'CLI --id3-yer command executed successfully' );
    
    my $ref = mp3::get_tags($test_file);
    my %tags = %$ref;
    is( $tags{year}, '2025', 'Year tag correctly set via CLI' );
    
    unlink($test_file);
}

# Test Comment Tag Setting
{
    my $test_file = "$temp_dir/test_comment.mp3";
    copy($source_mp3, $test_file);
    
    my $cmd = qq{perl namefix-cli.pl --id3-com="Test Comment" --id3-overwrite --process "$test_file"};
    my $output = qx($cmd 2>&1);
    my $exit_code = $? >> 8;
    
    ok( $exit_code == 0, 'CLI --id3-com command executed successfully' );
    
    my $ref = mp3::get_tags($test_file);
    my %tags = %$ref;
    is( $tags{comment}, 'Test Comment', 'Comment tag correctly set via CLI' );
    
    unlink($test_file);
}

# Test Genre Tag Setting
{
    my $test_file = "$temp_dir/test_genre.mp3";
    copy($source_mp3, $test_file);
    
    my $cmd = qq{perl namefix-cli.pl --id3-gen="Electronic" --id3-overwrite --process "$test_file"};
    my $output = qx($cmd 2>&1);
    my $exit_code = $? >> 8;
    
    ok( $exit_code == 0, 'CLI --id3-gen command executed successfully' );
    
    my $ref = mp3::get_tags($test_file);
    my %tags = %$ref;
    is( $tags{genre}, 'Electronic', 'Genre tag correctly set via CLI' );
    
    unlink($test_file);
}

#=============================================================================
# Multiple Tag Setting Test
#=============================================================================

# Test setting multiple tags at once
{
    my $test_file = "$temp_dir/test_multiple.mp3";
    copy($source_mp3, $test_file);
    
    my $cmd = qq{perl namefix-cli.pl --id3-art="Multi Artist" --id3-tit="Multi Title" --id3-alb="Multi Album" --id3-tra="03" --id3-yer="2024" --id3-overwrite --process "$test_file"};
    my $output = qx($cmd 2>&1);
    my $exit_code = $? >> 8;
    
    ok( $exit_code == 0, 'CLI multiple tag setting executed successfully' );
    
    my $ref = mp3::get_tags($test_file);
    my %tags = %$ref;
    is( $tags{artist}, 'Multi Artist', 'Multiple tags: Artist set correctly' );
    is( $tags{title}, 'Multi Title', 'Multiple tags: Title set correctly' );
    is( $tags{album}, 'Multi Album', 'Multiple tags: Album set correctly' );
    is( $tags{track}, '03', 'Multiple tags: Track set correctly' );
    is( $tags{year}, '2024', 'Multiple tags: Year set correctly' );
    
    unlink($test_file);
}

#=============================================================================
# Tag Guess Test
#=============================================================================

# Test tag guessing from filename
{
    my $test_file = "$temp_dir/Artist - Title.mp3";
    copy($source_mp3, $test_file);
    
    my $cmd = qq{perl namefix-cli.pl --id3-guess --process "$test_file"};
    my $output = qx($cmd 2>&1);
    my $exit_code = $? >> 8;
    
    ok( $exit_code == 0, 'CLI --id3-guess command executed successfully' );
    like( $output, qr/Processing|would have|modified/, 'Tag guessing output received' );
    
    my $ref = mp3::get_tags($test_file);
    my %tags = %$ref;
    ok( defined $tags{artist} || defined $tags{title}, 'Tag guessing extracted some tag information' );
    
    unlink($test_file);
}

#=============================================================================
# Tag Overwrite Test
#=============================================================================

# Test overwrite functionality
{
    my $test_file = "$temp_dir/test_overwrite.mp3";
    copy($source_mp3, $test_file);
    
    # First set a tag
    my $cmd1 = qq{perl namefix-cli.pl --id3-art="Original Artist" --process "$test_file"};
    qx($cmd1 2>&1);
    
    # Then overwrite it
    my $cmd2 = qq{perl namefix-cli.pl --id3-overwrite --id3-art="New Artist" --process "$test_file"};
    my $output = qx($cmd2 2>&1);
    my $exit_code = $? >> 8;
    
    ok( $exit_code == 0, 'CLI --id3-overwrite command executed successfully' );
    
    my $ref = mp3::get_tags($test_file);
    my %tags = %$ref;
    is( $tags{artist}, 'New Artist', 'Tag overwrite functionality works' );
    
    unlink($test_file);
}

#=============================================================================
# Tag Removal Tests
#=============================================================================

# Test ID3v1 tag removal
{
    my $test_file = "$temp_dir/test_rm_v1.mp3";
    copy($source_mp3, $test_file);
    
    # First add some tags
    my $cmd1 = qq{perl namefix-cli.pl --id3-art="Remove Me" --process "$test_file"};
    qx($cmd1 2>&1);
    
    # Then remove v1 tags
    my $cmd2 = qq{perl namefix-cli.pl --id3-rm-v1 --process "$test_file"};
    my $output = qx($cmd2 2>&1);
    my $exit_code = $? >> 8;
    
    ok( $exit_code == 0, 'CLI --id3-rm-v1 command executed successfully' );
    like( $output, qr/Processing|would have|modified/, 'ID3v1 removal output received' );
    
    unlink($test_file);
}

# Test ID3v2 tag removal
{
    my $test_file = "$temp_dir/test_rm_v2.mp3";
    copy($source_mp3, $test_file);
    
    # First add some tags
    my $cmd1 = qq{perl namefix-cli.pl --id3-art="Remove Me Too" --process "$test_file"};
    qx($cmd1 2>&1);
    
    # Then remove v2 tags
    my $cmd2 = qq{perl namefix-cli.pl --id3-rm-v2 --process "$test_file"};
    my $output = qx($cmd2 2>&1);
    my $exit_code = $? >> 8;
    
    ok( $exit_code == 0, 'CLI --id3-rm-v2 command executed successfully' );
    like( $output, qr/Processing|would have|modified/, 'ID3v2 removal output received' );
    
    unlink($test_file);
}

#=============================================================================
# ID3 Filename From Tag Tests
# Test --id3-fn-from-tag with all 4 style options (0-3)
#=============================================================================

# Test Style 0: Artist - Title.mp3
{
    my $test_file = "$temp_dir/test_fn_style0.mp3";
    copy($source_mp3, $test_file);
    
    # Set known tag values first
    my $cmd1 = qq{perl namefix-cli.pl --id3-art="ARTIST" --id3-tit="TITLE" --id3-tra="01" --id3-gen="METAL" --id3-alb="ALBUM" --id3-overwrite --process "$test_file"};
    qx($cmd1 2>&1);
    
    # Now test filename generation with style 0
    my $cmd2 = qq{perl namefix-cli.pl --id3-fn-from-tag --id3-fn-style=0 --process "$test_file"};
    my $output = qx($cmd2 2>&1);
    my $exit_code = $? >> 8;
    
    ok( $exit_code == 0, 'CLI --id3-fn-from-tag style 0 command executed successfully' );
    
    # Check if the expected filename exists (Artist - Title.mp3)
    my $expected_file = "$temp_dir/ARTIST - TITLE.mp3";
    ok( -f $expected_file, 'Style 0: Artist - Title.mp3 filename generated correctly' );
    
    unlink($test_file) if -f $test_file;
    unlink($expected_file) if -f $expected_file;
}

# Test Style 1: Artist - Track - Title.mp3
{
    my $test_file = "$temp_dir/test_fn_style1.mp3";
    copy($source_mp3, $test_file);
    
    # Set known tag values first
    my $cmd1 = qq{perl namefix-cli.pl --id3-art="ARTIST" --id3-tit="TITLE" --id3-tra="01" --id3-gen="METAL" --id3-alb="ALBUM" --id3-overwrite --process "$test_file"};
    qx($cmd1 2>&1);
    
    # Now test filename generation with style 1
    my $cmd2 = qq{perl namefix-cli.pl --id3-fn-from-tag --id3-fn-style=1 --process "$test_file"};
    my $output = qx($cmd2 2>&1);
    my $exit_code = $? >> 8;
    
    ok( $exit_code == 0, 'CLI --id3-fn-from-tag style 1 command executed successfully' );
    
    # Check if the expected filename exists (Artist - Track - Title.mp3)
    my $expected_file = "$temp_dir/ARTIST - 01 - TITLE.mp3";
    ok( -f $expected_file, 'Style 1: Artist - Track - Title.mp3 filename generated correctly' );
    
    unlink($test_file) if -f $test_file;
    unlink($expected_file) if -f $expected_file;
}

# Test Style 2: Artist - Album - Title.mp3
{
    my $test_file = "$temp_dir/test_fn_style2.mp3";
    copy($source_mp3, $test_file);
    
    # Set known tag values first
    my $cmd1 = qq{perl namefix-cli.pl --id3-art="ARTIST" --id3-tit="TITLE" --id3-tra="01" --id3-gen="METAL" --id3-alb="ALBUM" --id3-overwrite --process "$test_file"};
    qx($cmd1 2>&1);
    
    # Now test filename generation with style 2
    my $cmd2 = qq{perl namefix-cli.pl --id3-fn-from-tag --id3-fn-style=2 --process "$test_file"};
    my $output = qx($cmd2 2>&1);
    my $exit_code = $? >> 8;
    
    ok( $exit_code == 0, 'CLI --id3-fn-from-tag style 2 command executed successfully' );
    
    # Check if the expected filename exists (Artist - Album - Title.mp3)
    my $expected_file = "$temp_dir/ARTIST - ALBUM - TITLE.mp3";
    ok( -f $expected_file, 'Style 2: Artist - Album - Title.mp3 filename generated correctly' );
    
    unlink($test_file) if -f $test_file;
    unlink($expected_file) if -f $expected_file;
}

# Test Style 3: Artist - Album - Track - Title.mp3
{
    my $test_file = "$temp_dir/test_fn_style3.mp3";
    copy($source_mp3, $test_file);
    
    # Set known tag values first
    my $cmd1 = qq{perl namefix-cli.pl --id3-art="ARTIST" --id3-tit="TITLE" --id3-tra="01" --id3-gen="METAL" --id3-alb="ALBUM" --id3-overwrite --process "$test_file"};
    qx($cmd1 2>&1);
    
    # Now test filename generation with style 3
    my $cmd2 = qq{perl namefix-cli.pl --id3-fn-from-tag --id3-fn-style=3 --process "$test_file"};
    my $output = qx($cmd2 2>&1);
    my $exit_code = $? >> 8;
    
    ok( $exit_code == 0, 'CLI --id3-fn-from-tag style 3 command executed successfully' );
    
    # Check if the expected filename exists (Artist - Album - Track - Title.mp3)
    my $expected_file = "$temp_dir/ARTIST - ALBUM - 01 - TITLE.mp3";
    ok( -f $expected_file, 'Style 3: Artist - Album - Track - Title.mp3 filename generated correctly' );
    
    unlink($test_file) if -f $test_file;
    unlink($expected_file) if -f $expected_file;
}

# Test default style (should be 0) when --id3-fn-style is not specified
{
    my $test_file = "$temp_dir/test_fn_default.mp3";
    copy($source_mp3, $test_file);
    
    # Set known tag values first
    my $cmd1 = qq{perl namefix-cli.pl --id3-art="DEFAULT_ARTIST" --id3-tit="DEFAULT_TITLE" --id3-overwrite --process "$test_file"};
    qx($cmd1 2>&1);
    
    # Now test filename generation without specifying style (should default to 0)
    my $cmd2 = qq{perl namefix-cli.pl --id3-fn-from-tag --process "$test_file"};
    my $output = qx($cmd2 2>&1);
    my $exit_code = $? >> 8;
    
    ok( $exit_code == 0, 'CLI --id3-fn-from-tag default style command executed successfully' );
    
    # Check if the expected filename exists (should be style 0: Artist - Title.mp3)
    my $expected_file = "$temp_dir/DEFAULT_ARTIST - DEFAULT_TITLE.mp3";
    ok( -f $expected_file, 'Default style: Artist - Title.mp3 filename generated correctly (defaults to style 0)' );
    
    unlink($test_file) if -f $test_file;
    unlink($expected_file) if -f $expected_file;
}

# Test error handling when tags are missing
{
    my $test_file = "$temp_dir/test_fn_missing_tags.mp3";
    copy($source_mp3, $test_file);
    
    # Clear any existing tags first
    my $cmd1 = qq{perl namefix-cli.pl --id3-rm-v1 --id3-rm-v2 --process "$test_file"};
    qx($cmd1 2>&1);
    
    # Now try filename generation with missing tags
    my $cmd2 = qq{perl namefix-cli.pl --id3-fn-from-tag --id3-fn-style=0 --process "$test_file"};
    my $output = qx($cmd2 2>&1);
    my $exit_code = $? >> 8;
    
    ok( $exit_code == 0, 'CLI --id3-fn-from-tag with missing tags executed without fatal error' );
    like( $output, qr/Processing|would have|modified|missing|empty/, 'Missing tags handled gracefully with appropriate output' );
    
    unlink($test_file) if -f $test_file;
}

#=============================================================================
# Cleanup
#=============================================================================

# Clean up test files
unlink($test_mp3) if -f $test_mp3;
ok( ! -f $test_mp3, 'Test MP3 file cleaned up' );

exit;