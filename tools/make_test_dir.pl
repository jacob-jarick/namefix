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

my @vid_filetypes = ('mpg','mpeg','avi','asf','wmf','wmv','mkv');
my @pic_filetypes = ('jpeg','jpg','gif','bmp','png');
my @music_filetypes = ('mp3','mpc','ogg','flac');

my @bands = ('acdc', 'Blur', 'ZZ Top', 'NIN', 'Queen');

my $music_dir = "$dir/music";
mkdir $music_dir;

for my $band(@bands)
{
	for my $i (01..13)
	{
		my $r = int (rand(3)+1);
		my $title = join(" ", rand_words( size => $r ));

		my $filename = "$music_dir/$band - $i - $title.mp3";
		print "$filename\n";

		touch $filename;
	}
}

my $movies = "$dir/Movies";
mkdir $movies;

for(0..100)
{
	my $year = int(rand(75) +  1949);

	my $r = int (rand(3)+1);
	my $title = join(" ", rand_words( size => $r ));
	my $filename;

	$filename = "$movies/$title - $year.avi";

	if(rand(1) > 0.2)
	{
		$filename = "$movies/$title - ($year).avi";
	}
	if(rand(1) > 0.2)
	{
		$filename = "$movies/$title [$year].avi";
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
}

my $pic_dir = "$dir/Porn";
mkdir $pic_dir;

for my $i (01..1000)
{
	my $r = int (rand(3)+1);
	my $title = join(" ", rand_words( size => $r ));

	my $filename = "$pic_dir/$title." . $pic_filetypes[int(rand($#pic_filetypes))];
	print "$filename\n";

	touch $filename;
}

