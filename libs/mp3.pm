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
    my $com = "";

    my $exts = join('|', @globals::id3v2_exts);

	if($filename =~ /^(\d+)( - |\. )(.*?)( - )(.*?)\.($globals::id3_ext_regex)$/i)
	{
		&misc::plog(4, "sub guess_tags: track - artist - title");
		$tra = $1;
		$art = $3;
		$tit = $5;
	}

	elsif($filename =~ /^(\d+)( - |\. )(.*?)\.($globals::id3_ext_regex)$/i)
	{
		&misc::plog(4, "sub guess_tags: track - title");
		$tra = $1;
		$tit = $3;
	}

	elsif($filename =~ /^(.*?)( - )(.*?)( - )(\d+)( - )(.*)\.($globals::id3_ext_regex)$/i)
	{
		&misc::plog(4, "sub guess_tags: artist - ablum - track - title");
		$art = $1;
		$alb = $3;
		$tra = $5;
		$tit = $7;
	}

	# mems prefered format
	elsif($filename =~ /^(.*?)( - )(\d+)( - )(.*)\.($globals::id3_ext_regex)$/i)
	{
		&misc::plog(4, "sub guess_tags: artist - track - title");
		$art = $1;
		$tra = $3;
		$tit = $5;
		$alb = "";	# get this later
	}

	elsif($filename =~ /^(.*?)( - )(.*)\.($globals::id3_ext_regex)$/)
	{
		&misc::plog(4, "sub guess_tags: artist - title");
		$art = $1;
		$tit = $3;
		$tra = "";
		$alb = "";	# get this later
	}
	&misc::plog(4, "sub guess_tags: returning art = \"$art\", track = \"$tra\", title = \"$tit\", album = \"$alb\"");
	return($art, $tra, $tit, $alb);
}

1;
