# -----------------------------------------------------------------------------------
# mems mp3 funcs
# -----------------------------------------------------------------------------------

package mp3;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;

use Data::Dumper::Concise;
use MP3::Tag;

my %id3h = ();

$id3h{artist}	= 'TPE1';
$id3h{title}	= 'TIT2';
$id3h{track}	= 'TRCK';
$id3h{album}	= 'TALB';
$id3h{comment}	= 'COMM';
$id3h{genre}	= 'TCON';
$id3h{year}	    = 'TYER';

our %id3_order = ();
{
	my $count = 0;
	$id3_order{artist}	= $count++;
	$id3_order{track}	= $count++;
	$id3_order{title}	= $count++;
	$id3_order{album}	= $count++;
	$id3_order{genre}	= $count++;
	$id3_order{year}	= $count++;
	$id3_order{comment}	= $count++;
}

our %template = ();
$template{artist}	= '';
$template{track}	= '';
$template{title}	= '';
$template{album}	= '';
$template{genre}	= '';
$template{year}		= '';
$template{comment}	= '';

# -----------------------------------------------------------------------------------
# get tags
# -----------------------------------------------------------------------------------

sub get_tags
{
	my $filepath	= shift;
	&misc::quit("get_tags \$filepath is undef") if !defined $filepath;

    my %tag_hash 		= ();
    $tag_hash{artist}	= '';	# artist
    $tag_hash{title}	= '';	# track title
    $tag_hash{track}	= '';	# track number
    $tag_hash{album}	= '';	# album
    $tag_hash{genre}	= '';	# genre
    $tag_hash{year}		= '';	# year
    $tag_hash{comment}	= '';	# comment

    return \%tag_hash	if $filepath !~ /\.$globals::id3_ext_regex$/i;

	&misc::quit("get_tags '$filepath' not found") if !-f $filepath;

	my $audio_tags		= MP3::Tag->new($filepath);

	$tag_hash{title}	= $audio_tags->title	if defined $audio_tags->title;
	$tag_hash{artist} 	= $audio_tags->artist	if defined $audio_tags->artist;
	$tag_hash{album}	= $audio_tags->album	if defined $audio_tags->album;
	$tag_hash{year}		= $audio_tags->year	    if defined $audio_tags->year;
	$tag_hash{comment}	= $audio_tags->comment	if defined $audio_tags->comment;
	$tag_hash{track}	= $audio_tags->track	if defined $audio_tags->track;
	$tag_hash{genre}	= $audio_tags->genre	if defined $audio_tags->genre;

	$audio_tags->close();

	return (\%tag_hash);
}

sub rm_tags
{
	my $filepath 	= shift;
	
	&misc::quit("mp3::rm_tags: \$filepath is undef") if !defined $filepath;
	&misc::quit("mp3::rm_tags: file '$filepath' not found") if !-f $filepath;
	
	my $audio_tags = MP3::Tag->new($filepath);

	&misc::plog(3, "sub rm_tags: file = \"$filepath\"");

	$audio_tags->get_tags();

	if(exists $audio_tags->{ID3v1})
	{
        $audio_tags->{ID3v1}->remove_tag();
        $globals::tags_rm_count++;
    }

    if(exists $audio_tags->{ID3v2})
	{
        $audio_tags->{ID3v2}->remove_tag();
        $globals::tags_rm_count++;
    }

    return;
}

sub write_tags
{
	my $filepath = shift;

	&misc::quit("mp3::write_tags: \$filepath is undef")			if ! defined $filepath;
	&misc::quit("mp3::write_tags: \$filepath eq ''") 			if $filepath eq '';
	&misc::quit("mp3::write_tags: file '$filepath' not found")	if !-f $filepath;

	&misc::quit("mp3::write_tags: \$filepath  '$filepath' is not an audio file\n") if $filepath !~ /\.$globals::id3_ext_regex$/i;

	my $ref = shift;
	my %tag_hash = %$ref;

	&misc::quit("mp3::write_tags: tag_hash is undef") if ! defined $tag_hash{title};

    # ensure all fieldss have been sent
    for my $k(keys %id3h)
    {
        if(!defined $tag_hash{$k})
        {
            &misc::quit("ERROR: write_tags incomplete hash received. \$tag_hash{$k} is undefined\n" . Dumper(\%tag_hash));
        }
    }
    # ensure no extra keys in hash
    for my $k(keys %tag_hash)
    {
        if(!defined $id3h{$k})
        {
            &misc::quit("ERROR: write_tags extra key '$k' in hash.\n" . Dumper(\%tag_hash));
        }
    }

	my $audio_tags = MP3::Tag->new($filepath);

	$audio_tags->title_set	($tag_hash{title});
	$audio_tags->artist_set	($tag_hash{artist});
	$audio_tags->album_set	($tag_hash{album});
	$audio_tags->year_set	($tag_hash{year});
	$audio_tags->comment_set($tag_hash{comment});
	$audio_tags->track_set	($tag_hash{track});
	$audio_tags->genre_set	($tag_hash{genre});

	$audio_tags->update_tags();
	$audio_tags->close();
}

sub guess_tags
{
	&misc::plog(3, "sub guess_tags: \$filename\"");

	my $filename = shift;

	my $tag = "";
	my $art = "";
	my $tra = "";
	my $tit = "";
	my $alb = "";


	if($filename !~ /\.$globals::id3_ext_regex$/i)
	{
		&misc::plog(4, "sub guess_tags: not an audio file");
		return($art, $tra, $tit, $alb);
	}

	my $detected_style = -1;

	# 01 - ACDC - Thunderstruck.mp3
	# Track - Artist - Title
	if($filename =~ /^(\d+) - (.+?) - (.+?)\.[A-Za-z0-9]+?$/i)
	{
		$tra = $1;
		$art = $2;
		$tit = $3;
		$detected_style = "track - artist - title";
	}

	# Artist - Album - Track - Title.mp3
	# Metallica - Black - 01 - Enter Sandman.mp3
	elsif($filename =~ /^(.+?) - (.+?) - (\d+) - (.+)\.[A-Za-z0-9]+?$/i)
	{
		$art = $1;
		$alb = $2;
		$tra = $3;
		$tit = $4;
		$detected_style = "artist - album - track - title";
	}

	# mems prefered format
	# Artist - Track - Title.mp3
	elsif($filename =~ /^(.+?) - (\d+) - (.+)\.[A-Za-z0-9]+?$/i)
	{
		$art = $1;
		$tra = $2;
		$tit = $3;
		$detected_style = "artist - track - title";
	}

	# Artist - Title.mp3
	# ACDC - Thunderstruck.mp3
	elsif($filename =~ /^([^\-]+?) - ([^\-]+?)\.[A-Za-z0-9]+?$/i)
	{
		$art = $1;
		$tit = $2;
		$detected_style = "artist - title";
	}

	&misc::plog(4, "guess_tags detected style '$detected_style', returning art = \"$art\", track = \"$tra\", title = \"$tit\", album = \"$alb\"");
	return($art, $tra, $tit, $alb);
}

1;
