package log;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;

our @output	= ();
our $pos	= 0;
our %hash	= ();
our $size	= 100;

our %tags = ();
$tags{0}	= 'error';
$tags{1}	= 'warning';
$tags{2}	= 'message';
$tags{3}	= 'info';
$tags{4}	= 'info';
$tags{5}	= 'info';


sub add
{
	my $level	= shift;
	my $text	= shift;

	&main::quit("add: \$level is undef") if ! defined $level;
	&main::quit("add: \$level '$level' is not a number") if $level !~ /^\d+$/;
	&main::quit("add: \$text is undef") if ! defined $text;

	&prune	if scalar %hash > $size;

	if($text !~ /\n/ && length $text > 2 && $text ne ' ' && $text ne '')
	{
		$text .= "\n";
	}
	$hash{$pos}{level} = $level;
	$hash{$pos}{text} = $text;
	&draw($pos);
	$pos++;
}

sub draw
{
	my $k = shift;

	if(defined $main::log_box) # plog can occur before gui is ready
	{
		$main::log_box->tag('configure', 'message',	-font=>$style::hash{message}{font},	-foreground=>$style::hash{message}{fgcol}, 	-background=>$style::hash{message}{bgcol});
		$main::log_box->tag('configure', 'error',	-font=>$style::hash{error}{font},	-foreground=>$style::hash{error}{fgcol},	-background=>$style::hash{error}{bgcol});
		$main::log_box->tag('configure', 'warning',	-font=>$style::hash{warning}{font},	-foreground=>$style::hash{warning}{fgcol},	-background=>$style::hash{warning}{bgcol});
		$main::log_box->tag('configure', 'info',	-font=>$style::hash{info}{font},	-foreground=>$style::hash{info}{fgcol},		-background=>$style::hash{info}{bgcol});
		$main::log_box->tag('configure', 'normal');

		my $mode = $tags{$hash{$k}{level}};
		$main::log_box->insert('end', $hash{$k}{text}, $mode);
 		$main::log_box->moveTextEnd;
	}
}

sub clear
{
	%hash = ();
	$main::log_box->Contents([]);
}

sub prune
{
	my $prune_limit = 10;
	my $count = 0;
	$main::log_box->Contents([]);
	for my $k (sort{$a <=> $b} keys %hash)
	{
		$count++;
		delete $hash{$k};
		last if $count >= $prune_limit;

	}
	for my $k (sort{$a <=> $b} keys %hash)
	{
		&draw($hash{$k}{level}, $hash{$k}{text});
	}
}



1;
