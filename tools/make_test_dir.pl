#!/usr/bin/perl

# makes test directories

use strict;
use warnings;
use File::Touch;
use Data::Dumper::Concise;
use Data::Random qw(:all);

if(! -d $ARGV[0])
{
	die "error need to provide a target directory. $!\n";
}

my $dir = $ARGV[0];

my @vid_filetypes = ('mpg','mpeg','avi','mkv');
my @pic_filetypes = ('jpeg','jpg','gif','bmp','png');
my @music_filetypes = ('mp3', 'ogg', 'flac');

my @bands = ('acdc', 'Blur', 'ZZ Top', 'NIN', 'Queen');

my %mime = ();

$mime{mp3}	= 'audio/mpeg';
$mime{ogg}	= 'audio/ogg';
$mime{flac}	= 'audio/flac';
$mime{mpeg}	= 'video/mpeg';
$mime{mpg}	= 'video/mpeg';
$mime{avi}	= 'video/x-msvideo';
$mime{mkv}	= 'video/x-matroska';

$mime{jpeg}	= 'image/jpeg';
$mime{jpg}	= 'image/jpeg';
$mime{gif}	= 'image/gif';
$mime{bmp}	= 'image/bmp';
$mime{png}	= 'image/png';

my $music_dir = "$dir/music";
mkdir $music_dir;

for my $band(@bands)
{
	for my $y (0..int(rand(8)))	# random number of albums for the band
	{
		my $year	= &get_year;
		my $album	= "$band - $year - " . join(" ", rand_words( size => int(rand(3)+1) ));
		my $album_dir	= "$music_dir/$album";
		my $ext		= $music_filetypes[int(rand($#music_filetypes))];

		mkdir $album_dir;

		for my $i (1..7+int(rand(8)))	# random number of songs per album
		{
			my $r = int (rand(3)+1);
			my $title = join(" ", rand_words( size => $r ));

			my $filename = "$album_dir/$band - $i - $title." . $ext;
			print "$filename\n";

			touch $filename;

			&set_mime($filename, $ext);
		}
	}
}

my $movies = "$dir/Movies";
mkdir $movies;

for(0..100)
{
	my $year	= &get_year;
	my $r		= int (rand(3)+1);
	my $title	= join(" ", rand_words( size => $r ));
	my $ext		= $vid_filetypes[int(rand($#vid_filetypes))];
	my $filename	= "$movies/$title - $year.$ext";

	if(rand(1) > 0.2)
	{
		$filename = "$movies/$title - ($year).$ext";
	}
	if(rand(1) > 0.2)
	{
		$filename = "$movies/$title [$year].$ext";
	}

	if(rand(1) > 0.5)
	{
		$filename = uc $filename;
	}
	if(rand(1) > 0.3)
	{
		$filename =~ s/\s+/_/g;
	}
	if(rand(1) > 0.3)
	{
		$filename =~ s/\s+/./g;
	}

	print "$filename\n";
	touch $filename;
	&set_mime($filename, $ext);
}

my $pic_dir = "$dir/Porn";
mkdir $pic_dir;

for my $i (01..200)
{
	my $r = int (rand(3)+1);
	my $title = join(" ", rand_words( size => $r ));

	my $ext = $pic_filetypes[int(rand($#pic_filetypes))];
	my $filename = "$pic_dir/$title.$ext";
	print "$filename\n";

	touch $filename;

	&set_mime($filename, $ext);
}

exit;

sub get_year
{
	my $year = int(rand(75) +  1949);
	return $year;
}

sub set_mime
{
	my $file = shift;
	my $ext = shift;

	if(defined $mime{$ext})
	{
		open(FILE, ">$file");
		print FILE $mime{$ext};
		close (FILE);
	}
}
