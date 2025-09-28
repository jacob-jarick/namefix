package jpegexif;

# jpegexif.pm - JPEG EXIF Data Management Module
# Pure Perl module for EXIF metadata operations on JPEG files
# Part of the namefix.pl project ecosystem
#
# Author: Jacob Jarick <mem.namefix\@gmail.com>
# License: GPL
# Created: September 28, 2025

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(has_exif_data list_exif_tags remove_exif_data is_exif_available get_exif_error);

# Module availability flag
our $exif_available;
our $exif_error;

# Check if Image::ExifTool is available
BEGIN 
{
    eval "use Image::ExifTool";
    if ($@) 
    {
        $exif_available = 0;
        $exif_error = "Image::ExifTool module is required but not installed.\nPlease install it using: cpan Image::ExifTool\nOr on Ubuntu/Debian: sudo apt-get install libimage-exiftool-perl";
    } 
    else 
    {
        $exif_available = 1;
        $exif_error = '';
    }
}

#=====================================================================================
# Public Functions
#=====================================================================================

=head1 NAME

jpegexif - JPEG EXIF metadata management module

=head1 SYNOPSIS

    use jpegexif;
    
    # Check if file has removable EXIF data
    if (has_exif_data($filepath)) 
    {
        # List EXIF tags
        my @tags = list_exif_tags($filepath);
        
        # Remove EXIF data
        my $result = remove_exif_data($filepath);
    }

=head1 FUNCTIONS

=head2 has_exif_data($filepath)

Returns true if the JPEG file contains writable EXIF metadata.
Returns false for files with only filesystem/structural metadata.

=cut

sub has_exif_data 
{
    my ($filepath) = @_;
    
    return 0 unless $exif_available;
    return 0 unless _is_jpeg_file($filepath);
    
    my $exifTool = Image::ExifTool->new();
    my $info = $exifTool->ImageInfo($filepath);
    
    # Count metadata tags, excluding basic file info
    # These are typically non-removable file structure tags
    my @excluded_tags = qw(
        FileSize FileName Directory FileModifyDate FileAccessDate FileCreateDate
        FilePermissions MIMEType FileType FileTypeExtension ExifByteOrder
        ImageWidth ImageHeight EncodingProcess BitsPerSample ColorComponents
        YCbCrSubSampling
    );
    my %excluded = map { $_ => 1 } @excluded_tags;
    
    # Count tags that are likely removable EXIF metadata
    my $metadata_count = 0;
    for my $tag (keys %$info) {
        next if $excluded{$tag};
        $metadata_count++;
    }
    
    # If we have metadata beyond basic file info, assume it's removable
    return $metadata_count > 0;
}

=head2 list_exif_tags($filepath)

Returns a hash reference of writable EXIF tags found in the file.
Only includes actual EXIF metadata, excludes filesystem information.

Returns undef on error or empty hashref if no EXIF data found.

=cut

sub list_exif_tags 
{
    my ($filepath) = @_;
    
    return undef unless $exif_available;
    return undef unless _is_jpeg_file($filepath);
    
    my $exifTool = Image::ExifTool->new();
    my $info = $exifTool->ImageInfo($filepath);
    
    # Return metadata tags, excluding basic file structure info
    my @excluded_tags = qw(
        FileSize FileName Directory FileModifyDate FileAccessDate FileCreateDate
        FilePermissions MIMEType FileType FileTypeExtension ExifByteOrder
        ImageWidth ImageHeight EncodingProcess BitsPerSample ColorComponents
        YCbCrSubSampling
    );
    my %excluded = map { $_ => 1 } @excluded_tags;
    
    # Get metadata tags (potentially removable)
    my %tags_found = ();
    for my $tag (keys %$info) 
    {
        next if $excluded{$tag};
        $tags_found{$tag} = $info->{$tag};
    }
    
    return \%tags_found;
}

=head2 remove_exif_data($filepath)

Removes all writable EXIF metadata from the JPEG file.
Preserves image quality and essential JPEG structure.

Returns:
- 1 on success
- 0 on failure 
- undef if not a JPEG file

=cut

sub remove_exif_data 
{
    my ($filepath) = @_;
    
    return undef unless $exif_available;
    return undef unless _is_jpeg_file($filepath);
    
    my $exifTool = Image::ExifTool->new();
    
    # Remove all writable EXIF/metadata tags
    $exifTool->SetNewValue('*');  # Remove all tags
    
    # Write the cleaned file
    my $result = $exifTool->WriteInfo($filepath);
    
    return $result ? 1 : 0;
}

=head2 is_exif_available()

Returns true if Image::ExifTool module is available and loaded successfully.
Returns false if the module is not installed or failed to load.

=cut

sub is_exif_available 
{
    return $exif_available;
}

=head2 get_exif_error()

Returns the error message if Image::ExifTool failed to load.
Returns empty string if module loaded successfully.

=cut

sub get_exif_error 
{
    return $exif_error;
}

=head2 get_last_error()

Returns the last error message from ExifTool operations.
Only works if is_exif_available() returns true.

=cut

sub get_last_error 
{
    return '' unless $exif_available;
    my $exifTool = Image::ExifTool->new();
    return $exifTool->GetValue('Error') || '';
}

#=====================================================================================
# Private Helper Functions
#=====================================================================================

sub _is_jpeg_file 
{
    my ($filepath) = @_;
    
    return 0 unless defined $filepath;
    return 0 unless -f $filepath;
    return $filepath =~ /\.jpe?g$/i;
}

#=====================================================================================
# Module Initialization
#=====================================================================================

1;  # Module loaded successfully

__END__

=head1 DESCRIPTION

This module provides a clean interface for JPEG EXIF metadata operations
within the namefix.pl ecosystem. It focuses specifically on writable EXIF
data, excluding filesystem metadata and structural JPEG information.

=head1 AUTHOR

Jacob Jarick <mem.namefix\@gmail.com>

=head1 LICENSE

GPL License

=head1 SEE ALSO

L<Image::ExifTool>

=cut