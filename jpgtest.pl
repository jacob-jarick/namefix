#!/usr/bin/perl -w

use strict;
use warnings;
use FindBin qw($Bin);

print "JPEG Test Utility for namefix.pl - Tiered Fallback System\n";
print "=========================================================\n\n";

print "Testing Tk module loading...\n";
eval { require Tk; };
if ($@) {
    print "ERROR: Cannot load Tk module: $@\n";
    exit 1;
}
print "OK: Tk module loaded successfully\n\n";

# Test JPEG support (Tier 1)
print "Testing Tk::JPEG module loading (Tier 1)...\n";
my $has_jpeg = 0;
eval { require Tk::JPEG; };
if ($@) {
    print "NOTICE: Cannot load Tk::JPEG module: $@\n";
    print "Will test fallback options...\n";
} else {
    print "OK: Tk::JPEG module loaded successfully\n";
    $has_jpeg = 1;
}
print "\n";

print "Testing MainWindow creation...\n";
my $mw;
eval { $mw = Tk::MainWindow->new(); };
if ($@) {
    print "ERROR: Cannot create MainWindow: $@\n";
    exit 1;
}
print "OK: MainWindow created successfully\n\n";

# Check if image file exists
my $image_path = "$Bin/data/mem.jpg";
if (!-f $image_path) {
    print "ERROR: Image file not found at $image_path\n";
    exit 1;
}
print "OK: Image file exists at $image_path\n\n";

# Tiered fallback system
my $image;
my $fallback_method = "none";

# Tier 1: Try Tk::JPEG
if ($has_jpeg) {
    print "Tier 1: Testing JPEG image loading with Tk::JPEG...\n";
    eval {
        $image = $mw->Photo(
            -format => 'jpeg',
            -file => $image_path
        );
    };
    if (!$@ && $image) {
        print "SUCCESS: JPEG image loaded successfully with Tk::JPEG!\n";
        print "Image dimensions: " . $image->width() . "x" . $image->height() . "\n";
        $fallback_method = "jpeg";
    } else {
        print "FAILED: Cannot load JPEG with Tk::JPEG: $@\n";
        undef $image;
    }
}

# Tier 2: Try pre-existing PPM file
if (!$image) {
    print "\nTier 2: Testing PPM fallback (pre-converted file)...\n";
    my $ppm_path = $image_path;
    $ppm_path =~ s/\.jpg$/.ppm/i;
    
    if (-f $ppm_path) {
        print "Found PPM file: $ppm_path\n";
        eval {
            $image = $mw->Photo(
                -format => 'ppm',
                -file => $ppm_path
            );
        };
        if (!$@ && $image) {
            print "SUCCESS: Image loaded successfully from PPM file!\n";
            print "Image dimensions: " . $image->width() . "x" . $image->height() . "\n";
            $fallback_method = "ppm";
        } else {
            print "FAILED: Cannot load PPM file: $@\n";
            undef $image;
        }
    } else {
        print "NOTICE: PPM file not found at $ppm_path\n";
        print "You can create it with: convert mem.jpg mem.ppm\n";
    }
}

# Tier 3: Plain text fallback
if (!$image) {
    print "\nTier 3: Using plain text fallback (no image display)\n";
    $fallback_method = "text";
}

# Display results
print "\n" . "=" x 50 . "\n";
print "FALLBACK TEST RESULTS:\n";
print "Fallback method used: $fallback_method\n";

if ($image) {
    print "Creating test window with image ($fallback_method method)...\n";
    $mw->title("JPEG Test - $fallback_method fallback");
    
    # Create frame for content
    my $frame = $mw->Frame()->pack(-fill => 'both', -expand => 1);
    
    # Add image
    $frame->Label(-image => $image)->pack(-pady => 10);
    
    # Add method info
    my $method_text = "Image loaded using: " . uc($fallback_method) . " method";
    $frame->Label(-text => $method_text, -font => ['Arial', 10, 'bold'])->pack();
    
    $frame->Button(
        -text => "Close", 
        -command => sub { $mw->destroy; }
    )->pack(-pady => 10);
    
    print "Test window created. Close it to exit.\n";
    $mw->MainLoop();
} else {
    print "Creating test window with text fallback...\n";
    $mw->title("JPEG Test - Text fallback");
    
    my $frame = $mw->Frame()->pack(-fill => 'both', -expand => 1, -padx => 20, -pady => 20);
    
    $frame->Label(
        -text => "[Green mohawk photo unavailable]\n(But the wild creativity lives on!)\n\nNo image display available",
        -font => ['Arial', 12],
        -justify => 'center',
        -fg => 'blue'
    )->pack(-pady => 20);
    
    $frame->Label(
        -text => "Image fallback method: TEXT ONLY",
        -font => ['Arial', 10, 'bold']
    )->pack();
    
    $frame->Button(
        -text => "Close", 
        -command => sub { $mw->destroy; }
    )->pack(-pady => 10);
    
    print "Test window created. Close it to exit.\n";
    $mw->MainLoop();
}

print "\nJPEG fallback test completed.\n";
print "Method used: $fallback_method\n";

