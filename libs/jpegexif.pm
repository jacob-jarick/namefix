package jpegexif;

# Uses Pure Perl module for EXIF metadata operations

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

sub has_exif_data 
{
    my $filepath = shift;
    
    return 0 unless $exif_available;
    
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
    for my $tag (keys %$info) 
	{
        next if $excluded{$tag};
        $metadata_count++;
    }
    
    # If we have metadata beyond basic file info, assume it's removable
    return $metadata_count > 0;
}

sub list_exif_tags 
{
    my $filepath = shift;
    
    return undef unless $exif_available;
    
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

sub remove_exif_data 
{
    my ($filepath) = @_;
    
    return undef unless $exif_available;
    
    my $exifTool = Image::ExifTool->new();
    
    # Remove all writable EXIF/metadata tags
    $exifTool->SetNewValue('*');  # Remove all tags
    
    # Write the cleaned file
    my $result = $exifTool->WriteInfo($filepath);
    
    return $result ? 1 : 0;
}

sub is_exif_available 
{
    return $exif_available;
}

sub get_exif_error 
{
    return $exif_error;
}

sub get_last_error 
{
    return '' unless $exif_available;

    my $exifTool = Image::ExifTool->new();
	
    return $exifTool->GetValue('Error') || '';
}

1;  