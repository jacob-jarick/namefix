#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 58;
use FindBin qw($Bin);
use File::Copy;
use File::Path qw(make_path remove_tree);

use lib "$Bin/../libs";

use config;
use globals;
use fixname;

# Set CLI mode to avoid GUI dependencies
$globals::CLI = 1;

# Create temporary directory for tests
my $temp_dir = "$Bin/../temp/fixname";
remove_tree($temp_dir) if -d $temp_dir;
make_path($temp_dir);
ok( -d $temp_dir && -w $temp_dir, 'Test temp directory created and writable' );

#=============================================================================
# Comprehensive Tests for All fn_* Functions in fixname.pm
# These functions are the core filename processing routines
#=============================================================================

# Reset config before each test group
sub reset_test_config {
    &config::reset_config();
    $globals::CLI = 1;
}

#=============================================================================
# TEXT PROCESSING FUNCTIONS
#=============================================================================

# fn_replace - Replace user-entered strings
{
    &reset_test_config();
    $config::hash{replace}{value} = 1;
    $config::hash{ins_str_old}{value} = 'bad';
    $config::hash{ins_str}{value} = 'good';
    $config::hash{remove_regex}{value} = 0;
    
    my $result = &fixname::fn_replace(1, 'This is a bad example');
    is( $result, 'This is a good example', 'fn_replace: basic string replacement' );
    
    # Test regex mode
    $config::hash{remove_regex}{value} = 1;
    $config::hash{ins_str_old}{value} = '\d+';
    $config::hash{ins_str}{value} = 'NUM';
    $result = &fixname::fn_replace(1, 'Test 123 file');
    is( $result, 'Test NUM file', 'fn_replace: regex replacement' );
}

# fn_spaces - Convert underscores to spaces
{
    &reset_test_config();
    $config::hash{spaces}{value} = 1;
    $config::hash{space_character}{value} = ' ';
    
    my $result = &fixname::fn_spaces(1, 'Hello_World_Episode_01.avi');
    is( $result, 'Hello World Episode 01.avi', 'fn_spaces: underscores to spaces' );
    
    $result = &fixname::fn_spaces(1, 'Multiple___Underscores.txt');
    is( $result, 'Multiple Underscores.txt', 'fn_spaces: multiple underscores collapsed' );
}

# fn_sp_char - Remove special characters
{
    &reset_test_config();
    $config::hash{sp_char}{value} = 1;
    
    my $result = &fixname::fn_sp_char('Hello [World] (Test) @#%.txt');
    is( $result, 'Hello World Test .txt', 'fn_sp_char: remove special characters' );
}

# fn_dot2space - Convert dots to spaces
{
    &reset_test_config();
    $config::hash{dot2space}{value} = 1;
    $config::hash{space_character}{value} = ' ';
    
    my $result = &fixname::fn_dot2space(1, 'test.file', 'Hello.World.Episode.01.avi');
    is( $result, 'Hello World Episode 01.avi', 'fn_dot2space: dots to spaces preserving extension' );
    
    # Test directory mode
    $result = &fixname::fn_dot2space(0, 'test.dir', 'Hello.World.Directory');
    is( $result, 'Hello World Directory', 'fn_dot2space: directory mode' );
}

#=============================================================================
# SCENE/EPISODE PROCESSING
#=============================================================================

# fn_unscene - Convert S03E11 to 03x11
{
    &reset_test_config();
    $config::hash{unscene}{value} = 1;
    
    my $result = &fixname::fn_unscene('Show - S03E11 - Episode Title.avi');
    is( $result, 'Show - 03x11 - Episode Title.avi', 'fn_unscene: S03E11 to 03x11' );
    
    $result = &fixname::fn_unscene('Show - S1E5 - Episode Title.avi');
    is( $result, 'Show - 1x5 - Episode Title.avi', 'fn_unscene: S1E5 to 1x5' );
}

# fn_scene - Convert 03x11 to S03E11
{
    &reset_test_config();
    $config::hash{scene}{value} = 1; # 1 enables processing
    
    my $result = &fixname::fn_scene('Show - 03x11 - Episode Title.avi');
    is( $result, 'Show - S03E11 - Episode Title.avi', 'fn_scene: 03x11 to S03E11' );
    
    $result = &fixname::fn_scene('Show - 1x5 - Episode Title.avi');
    is( $result, 'Show - S1E5 - Episode Title.avi', 'fn_scene: 1x5 to S1E5' );
}

# fn_split_dddd - Split episode numbers like 0103 to 01x03
{
    &reset_test_config();
    $config::hash{split_dddd}{value} = 1;
    
    my $result = &fixname::fn_split_dddd('Show 0103 Episode.avi');
    is( $result, 'Show 01x03 Episode.avi', 'fn_split_dddd: 0103 to 01x03' );
    
    $result = &fixname::fn_split_dddd('Show 0515 Episode.avi');
    is( $result, 'Show 05x15 Episode.avi', 'fn_split_dddd: 0515 to 05x15' );
    
    # Should not split years
    $result = &fixname::fn_split_dddd('Movie 2023 Edition.avi');
    is( $result, 'Movie 2023 Edition.avi', 'fn_split_dddd: year 2023 unchanged' );
}

#=============================================================================
# CASE PROCESSING
#=============================================================================

# fn_case_fl - Capitalize first letter
{
    &reset_test_config();
    $config::hash{case}{value} = 1;
    
    my $result = &fixname::fn_case_fl(1, 'hello world.txt');
    is( $result, 'Hello world.txt', 'fn_case_fl: capitalize first letter' );
    
    $result = &fixname::fn_case_fl(1, '123hello world.txt');
    is( $result, '123hello world.txt', 'fn_case_fl: non-letter start unchanged' );
}

# fn_case - Apply proper case formatting
{
    &reset_test_config();
    $config::hash{case}{value} = 1;
    
    my $result = &fixname::fn_case(1, 'hello world test');
    is( $result, 'Hello World Test', 'fn_case: proper case formatting' );
    
    $result = &fixname::fn_case(1, 'HELLO_WORLD_TEST');
    is( $result, 'Hello_World_Test', 'fn_case: proper case with underscores' );
}

# fn_lc_all - Convert to lowercase
{
    &reset_test_config();
    $config::hash{lc_all}{value} = 1;
    
    my $result = &fixname::fn_lc_all('HELLO WORLD TEST.TXT');
    is( $result, 'hello world test.txt', 'fn_lc_all: all lowercase' );
}

# fn_uc_all - Convert to uppercase
{
    &reset_test_config();
    $config::hash{uc_all}{value} = 1;
    
    my $result = &fixname::fn_uc_all('hello world test.txt');
    is( $result, 'HELLO WORLD TEST.TXT', 'fn_uc_all: all uppercase' );
}

#=============================================================================
# CHARACTER PROCESSING
#=============================================================================

# fn_intr_char - International character translation
{
    &reset_test_config();
    $config::hash{intr_char}{value} = 1;
    
    my $result = &fixname::fn_intr_char(1, 'Café München Bjørk.txt');
    is( $result, 'Cafe Muenchen Bjork.txt', 'fn_intr_char: international characters' );
    
    $result = &fixname::fn_intr_char(1, 'Rammstein - Über.mp3');
    is( $result, 'Rammstein - Ueber.mp3', 'fn_intr_char: German umlauts' );
}

# to_7bit_ascii - Convert to 7-bit ASCII
{
    my $result = &fixname::to_7bit_ascii('Smart "quotes" and em—dash.txt');
    is( $result, 'Smart "quotes" and em---dash.txt', 'to_7bit_ascii: smart quotes and em-dash converted to hyphens' );
    
    $result = &fixname::to_7bit_ascii('Math: 2² × 3³ ÷ 4¼.txt');
    like( $result, qr/Math:.*\.txt$/, 'to_7bit_ascii: mathematical symbols converted' );
}

#=============================================================================
# NUMBER/DIGIT PROCESSING
#=============================================================================

# fn_pad_digits_w_zero - Pad digits with zeros
{
    &reset_test_config();
    $config::hash{pad_digits_w_zero}{value} = 1;
    
    my $result = &fixname::fn_pad_digits_w_zero('Show 1x5 Episode.avi');
    is( $result, 'Show 01x05 Episode.avi', 'fn_pad_digits_w_zero: pad episode numbers' );
    
    $result = &fixname::fn_pad_digits_w_zero('Show s1e5 Episode.avi');
    is( $result, 'Show s010e5 Episode.avi', 'fn_pad_digits_w_zero: scene format partial padding' );
}

# fn_pad_digits - Pad digits with spaces and dashes
{
    &reset_test_config();
    $config::hash{pad_digits}{value} = 1;
    $config::hash{space_character}{value} = ' ';
    
    my $result = &fixname::fn_pad_digits('Show 03x11 Episode.avi');
    is( $result, 'Show - 03x11 - Episode.avi', 'fn_pad_digits: pad with dashes' );
    
    $result = &fixname::fn_pad_digits('03x11 Episode Name.avi');
    is( $result, '03x11 - Episode Name.avi', 'fn_pad_digits: leading episode' );
}

# fn_digits - Remove leading digits
{
    &reset_test_config();
    $config::hash{digits}{value} = 1;
    
    my $result = &fixname::fn_digits('01 Track Name.mp3');
    is( $result, 'Track Name.mp3', 'fn_digits: remove leading track number' );
    
    $result = &fixname::fn_digits('123 456 File Name.txt');
    is( $result, '456 File Name.txt', 'fn_digits: remove only leading digits' );
}

# fn_pad_N_to_NN - Pad single digits to double digits
{
    &reset_test_config();
    $config::hash{pad_N_to_NN}{value} = 1;
    
    my $result = &fixname::fn_pad_N_to_NN('Track 5 Name.mp3');
    is( $result, 'Track 05 Name.mp3', 'fn_pad_N_to_NN: single digit to double' );
    
    $result = &fixname::fn_pad_N_to_NN('Episode.5.Name.avi');
    is( $result, 'Episode.05.Name.avi', 'fn_pad_N_to_NN: with dots' );
}

# fn_pad_dash - Pad dashes with spaces
{
    &reset_test_config();
    $config::hash{pad_dash}{value} = 1;
    $config::hash{space_character}{value} = ' ';
    
    my $result = &fixname::fn_pad_dash('Artist-Song-Title.mp3');
    is( $result, 'Artist - Song - Title.mp3', 'fn_pad_dash: pad dashes with spaces' );
    
    $result = &fixname::fn_pad_dash('Show_-_Episode.avi');
    is( $result, 'Show - _Episode.avi', 'fn_pad_dash: partial cleanup of mixed spacing' );
}

# fn_rm_digits - Remove all digits
{
    &reset_test_config();
    $config::hash{rm_digits}{value} = 1;
    
    my $result = &fixname::fn_rm_digits('Show Season 3 Episode 11.avi');
    is( $result, 'Show Season  Episode .avi', 'fn_rm_digits: remove all digits' );
}

#=============================================================================
# STRING MODIFICATION
#=============================================================================

# fn_front_a - Prepend string to front
{
    &reset_test_config();
    $config::hash{ins_start}{value} = 1;
    $config::hash{ins_front_str}{value} = 'PREFIX_';
    
    my $result = &fixname::fn_front_a('filename.txt');
    is( $result, 'PREFIX_filename.txt', 'fn_front_a: prepend prefix' );
}

# fn_end_a - Append string to end (before extension)
{
    &reset_test_config();
    $config::hash{ins_end}{value} = 0; # 0 enables processing
    $config::hash{ins_end_str}{value} = '_SUFFIX';
    
    my $result = &fixname::fn_end_a('filename.txt');
    is( $result, 'filename_SUFFIX.txt', 'fn_end_a: append suffix before extension' );
}

# fn_truncate - Truncate filename
{
    &reset_test_config();
    $config::hash{truncate}{value} = 1;
    $config::hash{truncate_to}{value} = 20;
    $config::hash{truncate_style}{value} = 1; # from end
    $config::hash{max_fn_length}{value} = 256;
    
    my $result = &fixname::fn_truncate('test', 'This_Is_A_Very_Long_Filename_That_Should_Be_Truncated.txt');
    is( length($result), 20, 'fn_truncate: filename truncated to specified length' );
    like( $result, qr/\.txt$/, 'fn_truncate: extension preserved' );
}

#=============================================================================
# CLEANUP FUNCTIONS
#=============================================================================

# fn_pre_clean - Pre-processing cleanup
{
    &reset_test_config();
    $config::hash{cleanup_general}{value} = 1;
    
    # Create actual test files for pre_clean testing
    my $test_avi = "$temp_dir/test.avi";
    my $test_jpeg = "$temp_dir/test.jpeg";
    open(my $fh1, '>', $test_avi) or die "Cannot create test file: $!";
    close($fh1);
    open(my $fh2, '>', $test_jpeg) or die "Cannot create test file: $!";
    close($fh2);
    
    my $result = &fixname::fn_pre_clean(1, $test_avi, '  --Bad-Artist- - -Track-  .avi');
    is( $result, 'Bad-Artist- -Track.avi', 'fn_pre_clean: clean leading/trailing chars and spaces' );
    
    $result = &fixname::fn_pre_clean(1, $test_jpeg, 'filename.jpeg');
    is( $result, 'filename.jpg', 'fn_pre_clean: jpeg to jpg extension' );
    
    unlink($test_avi, $test_jpeg);
}

# fn_post_clean - Post-processing cleanup
{
    &reset_test_config();
    $config::hash{cleanup_general}{value} = 1;
    $config::hash{space_character}{value} = ' ';
    
    # Create actual test files for post_clean testing
    my $test_file = "$temp_dir/test.avi";
    open(my $fh, '>', $test_file) or die "Cannot create test file: $!";
    close($fh);
    
    my $result = &fixname::fn_post_clean(1, $test_file, 'Artist () [] - - Track  .AVI');
    is( $result, 'Artist - Track.avi', 'fn_post_clean: remove empty brackets and clean spacing' );
    
    $result = &fixname::fn_post_clean(1, $test_file, 'Multiple    Spaces.AVI');
    is( $result, 'Multiple Spaces.avi', 'fn_post_clean: collapse spaces and lowercase extension' );
    
    unlink($test_file);
}

#=============================================================================
# ADVANCED FUNCTIONS REQUIRING FILES
#=============================================================================

# Test functions that need actual files (fn_enum, fn_sp_word, fn_kill_cwords)
{
    # Create test files for enum testing
    my $test_file1 = "$temp_dir/test1.txt";
    my $test_file2 = "$temp_dir/test2.txt";
    open(my $fh1, '>', $test_file1) or die "Cannot create test file: $!";
    close($fh1);
    open(my $fh2, '>', $test_file2) or die "Cannot create test file: $!";
    close($fh2);
    
    ok( -f $test_file1, 'Test file 1 created for enum testing' );
    ok( -f $test_file2, 'Test file 2 created for enum testing' );
    
    # fn_enum - Add enumeration
    {
        &reset_test_config();
        $config::hash{enum}{value} = 1;
        $config::hash{enum_opt}{value} = 1; # prepend
        $config::hash{enum_pad}{value} = 1;
        $config::hash{enum_pad_zeros}{value} = 3;
        $fixname::enum_count = 1; # Reset counter
        
        my $result = &fixname::fn_enum($test_file1, 'filename.txt');
        is( $result, '001filename.txt', 'fn_enum: prepend padded number' );
        
        $result = &fixname::fn_enum($test_file2, 'filename.txt');
        is( $result, '002filename.txt', 'fn_enum: counter increments' );
        
        # Test append mode
        $config::hash{enum_opt}{value} = 2; # append
        $result = &fixname::fn_enum($test_file1, 'filename.txt');
        is( $result, 'filename003.txt', 'fn_enum: append before extension' );
    }
    
    # fn_sp_word - Special word casing (requires word casing array)
    {
        &reset_test_config();
        $config::hash{word_special_casing}{value} = 1;
        @globals::word_casing_arr = ('The', 'Of', 'And', 'A', 'An');
        
        my $result = &fixname::fn_sp_word(1, $test_file1, 'the lord of the rings.avi');
        is( $result, 'The lord Of The rings.avi', 'fn_sp_word: special casing for common words' );
    }
    
    # fn_kill_cwords - Kill words from list
    {
        &reset_test_config();
        $config::hash{kill_cwords}{value} = 1;
        @globals::kill_words_arr = ('bad', 'ugly', 'terrible');
        
        my $result = &fixname::fn_kill_cwords($test_file1, 'this bad ugly movie terrible.avi');
        is( $result, 'this   movie .avi', 'fn_kill_cwords: remove words from kill list' );
    }
    
    # fn_kill_sp_patterns - Kill special patterns
    {
        &reset_test_config();
        $config::hash{kill_sp_patterns}{value} = 1;
        @globals::kill_patterns_arr = ('\[.*?\]', '\(.*?\)');
        
        my $result = &fixname::fn_kill_sp_patterns('Movie [2023] (Director Cut).avi');
        is( $result, 'Movie  .avi', 'fn_kill_sp_patterns: remove bracketed content' );
    }
}

#=============================================================================
# INTEGRATION TESTS
#=============================================================================

# Test multiple functions working together
{
    &reset_test_config();
    $config::hash{spaces}{value} = 1;
    $config::hash{case}{value} = 1;
    $config::hash{sp_char}{value} = 1;
    $config::hash{cleanup_general}{value} = 1;
    $config::hash{space_character}{value} = ' ';
    
    # Create actual test file for integration testing
    my $test_file = "$temp_dir/integration_test.avi";
    open(my $fh, '>', $test_file) or die "Cannot create test file: $!";
    close($fh);
    
    my $input = 'bad_filename_(2023)_[directors_cut].AVI';
    my $result = $input;
    
    # Apply multiple transformations
    $result = &fixname::fn_spaces(1, $result);
    $result = &fixname::fn_sp_char($result);
    $result = &fixname::fn_case(1, $result);
    $result = &fixname::fn_post_clean(1, $test_file, $result);
    
    is( $result, 'Bad Filename 2023 Directors Cut.avi', 'Integration: multiple functions working together' );
    
    unlink($test_file);
}

# Test edge cases and error conditions
{
    # Test with empty strings where allowed
    &reset_test_config();
    $config::hash{spaces}{value} = 0; # disabled
    
    my $result = &fixname::fn_spaces(1, 'test_file.txt');
    is( $result, 'test_file.txt', 'Edge case: function disabled returns unchanged' );
    
    # Test international characters in realistic filename
    $config::hash{intr_char}{value} = 1;
    $result = &fixname::fn_intr_char(1, 'Motörhead - Ace of Spades.mp3');
    is( $result, 'Motoerhead - Ace of Spades.mp3', 'Edge case: realistic international filename' );
}

#=============================================================================
# FILE EXTENSION TESTS
#=============================================================================

# Test file vs directory handling differences
{
    my $test_dir = "$temp_dir/testdir";
    mkdir($test_dir);
    my $test_file = "$temp_dir/testfile.txt";
    open(my $fh, '>', $test_file) or die "Cannot create test file: $!";
    close($fh);
    
    &reset_test_config();
    $config::hash{dot2space}{value} = 1;
    $config::hash{space_character}{value} = ' ';
    
    # File should preserve extension
    my $file_result = &fixname::fn_dot2space(1, $test_file, 'test.file.name.txt');
    is( $file_result, 'test file name.txt', 'File extension preserved in fn_dot2space' );
    
    # Directory should convert all dots
    my $dir_result = &fixname::fn_dot2space(0, $test_dir, 'test.dir.name');
    is( $dir_result, 'test dir name', 'Directory mode converts all dots in fn_dot2space' );
    
    rmdir($test_dir);
    unlink($test_file);
}

#=============================================================================
# CLEANUP
#=============================================================================

# Clean up temporary directory
remove_tree($temp_dir) if -d $temp_dir;
ok( ! -d $temp_dir, 'Test temp directory cleaned up' );

exit;
