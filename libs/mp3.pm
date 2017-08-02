# -----------------------------------------------------------------------------------
# mems mp3 funcs
# -----------------------------------------------------------------------------------

use strict;
#use warnings;

# -----------------------------------------------------------------------------------
# get tags
# -----------------------------------------------------------------------------------

sub get_tags
{
	&misc::plog(3, "sub get_tags:");
	my $file	= shift;

        my $art1	= "";
        my $tit1 	= "";
        my $tra1 	= "";
        my $alb1 	= "";
        my $com1 	= "";
        my $gen1	= "";
        my $year1	= "";

        my $art2	= "";
        my $tit2 	= "";
        my $tra2 	= "";
        my $alb2 	= "";
        my $com2 	= "";
        my $gen2	= "";
        my $year2	= "";

	my $mp3 = MP3::Tag->new($file);
	$mp3->get_tags();

       	if (exists $mp3->{ID3v1})
	{
		$art1 = $mp3->{ID3v1}->artist;
		$tit1 = $mp3->{ID3v1}->title;
		$tra1 = $mp3->{ID3v1}->track;
		$alb1 = $mp3->{ID3v1}->album;
		$com1 = $mp3->{ID3v1}->comment;
                $gen1 = $mp3->{ID3v1}->genre;
                $year1 = $mp3->{ID3v1}->year;
	}

       	if (exists $mp3->{ID3v2})
	{
		$art2 = $mp3->{ID3v2}->getFrame("TPE1");
		$tit2 = $mp3->{ID3v2}->getFrame("TIT2");
		$tra2 = $mp3->{ID3v2}->getFrame("TRCK");
		$alb2 = $mp3->{ID3v2}->getFrame("TALB");
		my $com = $mp3->{ID3v2}->getFrame("COMM");
                if($com)
		{
			$com2 = $com->{Text};
		}
                $gen2 = $mp3->{ID3v2}->getFrame("TCON");
                $year2 = $mp3->{ID3v2}->getFrame("TYER");

                # sort out which tags are complete, file in missing :)
	        if($art2 && !$art1)
		{
	                $art1 = $art2;
                       	$main::id3_writeme = 1;
	        }
		elsif(!$art2 && $art1)
		{
                       	$main::id3_writeme = 1;
	        }

	        if($tit2 && !$tit1)
		{
	                $tit1 = $tit2;
                       	$main::id3_writeme = 1;
	        }
                elsif(!$tit2 && $tit1)
		{
                       	$main::id3_writeme = 1;
	        }

	        if($tra2 && !$tra1)
		{
	                $tra1 = $tra2;
                       	$main::id3_writeme = 1;
	        }
                elsif(!$tra2 && $tra1)
		{
                       	$main::id3_writeme = 1;
	        }

	        if($alb2 && !$alb1)
		{
	                $alb1 = $alb2;
                       	$main::id3_writeme = 1;
	        }
		elsif(!$alb2 && $alb1)
		{
                       	$main::id3_writeme = 1;
	        }

	        if($com2 && !$com1)
		{
	                $com1 = $com2;
                       	$main::id3_writeme = 1;
	        }
                elsif(!$com2 && $com1)
		{
                       	$main::id3_writeme = 1;
	        }

	        if($gen2 && !$gen1)
		{
	                $gen1 = $gen2;
                       	$main::id3_writeme = 1;
	        }
                elsif(!$gen2 && $gen1)
		{
                       	$main::id3_writeme = 1;
	        }
	        if($year2 && !$year1)
		{
	                $year1 = $year2;
                       	$main::id3_writeme = 1;
	        }
                elsif(!$year2 && $year1)
		{
                       	$main::id3_writeme = 1;
	        }
	}
	$mp3->close();

        if (exists $mp3->{ID3v1} || exists $mp3->{ID3v2})
	{
		return("id3v1", $art1, $tit1, $tra1, $alb1, $gen1, $year1, $com1);
	}
	return("notag");
}

sub rm_tags
{
	my $file 	= shift;
	my $opt 	= shift;
	my $mp3 = MP3::Tag->new($file);

	&misc::plog(3, "sub rm_tags: file = \"$file\", opt = \"$opt\"");
        $mp3->get_tags();

        if($opt eq "id3v1" && exists $mp3->{ID3v1})
	{
		&misc::plog(4, "sub rm_tags: removing id3v1");
	        print "id3v1 tag from $file\n";
        	$mp3->{ID3v1}->remove_tag();
                $main::tags_rm++;
        }
        if($opt eq "id3v2" && exists $mp3->{ID3v2})
	{
		&misc::plog(4, "sub rm_tags: removing id3v2");
	        print "id3v2 tag from $file\n";
               	$mp3->{ID3v2}->remove_tag();
                $main::tags_rm++;
        }
        return;
}

sub write_tags
{
	my $file = shift;

	my $art = shift;
	my $tit = shift;
	my $tra = shift;
	my $alb = shift;
	my $com = shift;
        my $gen = shift;
        my $year = shift;

	&misc::plog(3, "sub write_tags: \"$file\"");
	my $mp3 = MP3::Tag->new($file);

	if (!$mp3->{ID3v1})
	{
		&misc::plog(4, "sub write_tags: id3v1 tag did not exist, creating");
		$mp3->new_tag("ID3v1");
	}

	if (!$mp3->{ID3v2})
	{
		&misc::plog(4, "sub write_tags: id3v2 tag did not exist, creating");
		$mp3->new_tag("ID3v2");
	}

	$mp3->get_tags();

	if($art)
	{
		&misc::plog(4, "sub write_tags: setting tag artist as \"$art\"");
		$mp3->{ID3v1}->artist($art);
		$mp3->{ID3v2}->remove_frame("TPE1");
                $mp3->{ID3v2}->add_frame("TPE1",$art);
	}
	if($tit)
	{
		&misc::plog(4, "sub write_tags: setting tag title as \"$tit\"");
		$mp3->{ID3v1}->title($tit);
                $mp3->{ID3v2}->remove_frame("TIT2");
		$mp3->{ID3v2}->add_frame("TIT2",$tit);
	}
	if($tra)
	{
		&misc::plog(4, "sub write_tags: setting tag Track as \"$tra\"");
		$mp3->{ID3v1}->track($tra);
                $mp3->{ID3v2}->remove_frame("TRCK");
		$mp3->{ID3v2}->add_frame("TRCK",$tra);
	}
	if($alb)
	{
		&misc::plog(4, "sub write_tags: setting tag album as \"$alb\"");
		$mp3->{ID3v1}->album($alb);
                $mp3->{ID3v2}->remove_frame("TALB");
       		$mp3->{ID3v2}->add_frame("TALB",$alb);
	}
	if($com)
	{
		&misc::plog(4, "sub write_tags: setting tag comment as \"$com\"");
		$mp3->{ID3v1}->comment($com);
                $mp3->{ID3v2}->remove_frame("COMM");
		$mp3->{ID3v2}->add_frame("COMM","ENG","",$com);
	}
        if($gen)
	{
		&misc::plog(4, "sub write_tags: setting genre artist as \"$gen\"");
		$mp3->{ID3v1}->genre($gen);
                $mp3->{ID3v2}->remove_frame("TCON");
                $mp3->{ID3v2}->add_frame("TCON",$gen);
        }
        if($year)
	{
		&misc::plog(4, "sub write_tags: setting tag year as \"$year\"");
        	$mp3->{ID3v1}->year($year);
        	$mp3->{ID3v2}->remove_frame("TYER");
        	$mp3->{ID3v2}->add_frame("TYER",$year);
        }

	&misc::plog(4, "sub write_tags: writting tags and closing mp3 file");
	$mp3->{ID3v1}->write_tag();
	$mp3->{ID3v2}->write_tag();

	$mp3->close();
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

	if($file =~ /^(\d+)( - |\. )(.*?)( - )(.*?)(\.mp3)/)
	{
		&misc::plog(4, "sub guess_tags: track - artist - title");
		$tra = $1;
		$art = $3;
		$tit = $5;
	}

	elsif($file =~ /^(\d+)( - |\. )(.*?)(\.mp3)/)
	{
		&misc::plog(4, "sub guess_tags: track - title");
		$tra = $1;
		$tit = $3;
	}

	elsif($file =~ /^(.*?)( - )(.*?)( - )(\d+)( - )(.*)(\.mp3)/)
	{
		&misc::plog(4, "sub guess_tags: artist - ablum - track - title");
		$art = $1;
		$alb = $3;
		$tra = $5;
		$tit = $7;
	}

	# mems prefered format
	elsif($file =~ /^(.*?)( - )(\d+)( - )(.*)(\.mp3)/)
	{
		&misc::plog(4, "sub guess_tags: artist - track - title");
		$art = $1;
		$tra = $3;
		$tit = $5;
		$alb = "";	# get this later
	}

	elsif($file =~ /^(.*?)( - )(.*)(\.mp3)/)
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