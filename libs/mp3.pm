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
$id3h{comment}	= 'COMM(fre,fra,eng,#0)';
$id3h{genre}	= 'TCON';
$id3h{year}	= 'TYER';

# -----------------------------------------------------------------------------------
# get tags
# -----------------------------------------------------------------------------------

sub get_tags
{
	my $file	= shift;
	die "get_tags \$file is undef\n" if(!defined $file);

        my %tag_hash = ();
        $tag_hash{artist} = '';		# artist
        $tag_hash{title} = '';		# track title
        $tag_hash{track} = '';		# track number
        $tag_hash{album} = '';		# album
        $tag_hash{genre} = '';		# genre
        $tag_hash{year} = '';		# year
        $tag_hash{comment} = '';	# comment

	my $audio_tags = MP3::Tag->new($file);
	$audio_tags->get_tags();

       	if (exists $audio_tags->{ID3v1})
	{
		$tag_hash{artist}	= $audio_tags->{ID3v1}->artist	if defined $audio_tags->{ID3v1}->artist;
		$tag_hash{title}	= $audio_tags->{ID3v1}->title	if defined $audio_tags->{ID3v1}->title;
		$tag_hash{track}	= $audio_tags->{ID3v1}->track	if defined $audio_tags->{ID3v1}->track;
		$tag_hash{album}	= $audio_tags->{ID3v1}->album	if defined $audio_tags->{ID3v1}->album;
		$tag_hash{comment}	= $audio_tags->{ID3v1}->comment	if defined $audio_tags->{ID3v1}->comment;
                $tag_hash{genre}	= $audio_tags->{ID3v1}->genre	if defined $audio_tags->{ID3v1}->genre;
                $tag_hash{year}		= $audio_tags->{ID3v1}->year	if defined $audio_tags->{ID3v1}->year;
	}

       	if (exists $audio_tags->{ID3v2})
	{
		for my $k(keys %mp3::id3h)
		{
			my $tmp = $audio_tags->{ID3v2}->getFrame($mp3::id3h{$k});
			if (defined $tmp)
			{
				if($k eq 'comment')
				{
					$tag_hash{$k} = '';
					if(defined $tmp->{Text})
					{
						$tag_hash{$k} = $tmp->{Text};
					}
					next;
				}
				$tag_hash{$k} = $tmp;
			}
		}
	}
	$audio_tags->close();

	return (\%tag_hash);
}

sub rm_tags
{
	my $file 	= shift;
	my $audio_tags = MP3::Tag->new($file);

	&misc::plog(3, "sub rm_tags: file = \"$file\"");

	$audio_tags->get_tags();

	if(exists $audio_tags->{ID3v1})
	{
        	$audio_tags->{ID3v1}->remove_tag();
                $main::tags_rm++;
        }
        if(exists $audio_tags->{ID3v2})
	{
               	$audio_tags->{ID3v2}->remove_tag();
                $main::tags_rm++;
        }
        return;
}

sub write_tags
{
	my $file = shift;
	print "write_tags \"$file\"\n";
	my $ref = shift;
        my %tag_hash = %$ref;

        # ensure all fieldss have been sent
        for my $k(keys %id3h)
        {
		if(!defined $tag_hash{$k})
		{
			print "ERROR: write_tags incomplete hash recieved. \$tag_hash{$k} is undefined\n";
			print Dumper(\%tag_hash);
			exit;
		}
        }
        # ensure all fieldss are valid
        for my $k(keys %tag_hash)
        {
		if(!defined $id3h{$k})
		{
			print "ERROR: write_tags uknown tag '$k' recieved.\n";
			print Dumper(\%tag_hash);
			exit;
		}
        }

	my $audio_tags = MP3::Tag->new($file);

# 	if (!$audio_tags->{ID3v1})
# 	{
# 		print "sub write_tags: id3v1 is undef, creating\n";
# 		$audio_tags->new_tag("ID3v1");
# 	}
#
# 	if (!$audio_tags->{ID3v2})
# 	{
# 		print "sub write_tags: id3v2 tag did not exist, creating\n";
# 		$audio_tags->new_tag("ID3v2");
# 	}

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
	&misc::plog(3, "sub guess_tags: \$file\"");

	my $file = shift;

        my $tag = "";
        my $art = "";
        my $tra = "";
        my $tit = "";
        my $alb = "";
        my $com = "";

        my $exts = join('|', @config::id3v2_exts);

	if($file =~ /^(\d+)( - |\. )(.*?)( - )(.*?)\.($config::id3_ext_regex)$/i)
	{
		&misc::plog(4, "sub guess_tags: track - artist - title");
		$tra = $1;
		$art = $3;
		$tit = $5;
	}

	elsif($file =~ /^(\d+)( - |\. )(.*?)\.($config::id3_ext_regex)$/i)
	{
		&misc::plog(4, "sub guess_tags: track - title");
		$tra = $1;
		$tit = $3;
	}

	elsif($file =~ /^(.*?)( - )(.*?)( - )(\d+)( - )(.*)\.($config::id3_ext_regex)$/i)
	{
		&misc::plog(4, "sub guess_tags: artist - ablum - track - title");
		$art = $1;
		$alb = $3;
		$tra = $5;
		$tit = $7;
	}

	# mems prefered format
	elsif($file =~ /^(.*?)( - )(\d+)( - )(.*)\.($config::id3_ext_regex)$/i)
	{
		&misc::plog(4, "sub guess_tags: artist - track - title");
		$art = $1;
		$tra = $3;
		$tit = $5;
		$alb = "";	# get this later
	}

	elsif($file =~ /^(.*?)( - )(.*)\.($config::id3_ext_regex)$/)
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