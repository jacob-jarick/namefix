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
$tags {-1}	= 'message';
$tags {0}	= 'error';
$tags {1}	= 'warning';
$tags {2}	= 'info';
$tags {3}	= 'info';
$tags {4}	= 'info';
$tags {5}	= 'info';
$tags {6}	= 'info';


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
		$main::log_box->tag('configure', 'message',	-foreground=>'blue', -background=>'yellow');
		$main::log_box->tag('configure', 'error',	-background=>'lightblue');
		$main::log_box->tag('configure', 'warning',	-foreground=>'black',	-background=>'yellow');
		$main::log_box->tag('configure', 'info',	-foreground=>'black',	-background=>'light blue');
		$main::log_box->tag('configure', 'normal');

		my $mode = $tags{$hash{$k}{level}};
		print "\$mode = $mode\n";
		$main::log_box->insert ('end', $hash{$k}{text}, $mode);
		$main::log_box->GotoLineNumber(-1);
	}
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
