package log;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;

use Data::Dumper::Concise;

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

	&prune	if (scalar keys %hash) > $size;

	if($text !~ /\n/ && length $text > 2 && $text ne ' ' && $text ne '')
	{
		$text .= "\n";
	}
	$hash{$pos}{level}	= $level;
	$hash{$pos}{text}	= $text;
	&draw($pos);
	$pos++;
}

sub draw
{
	my $k = shift;

	if(defined $main::log_box) # plog can occur before gui is ready
	{
		&main::quit("draw: \$hash{$k} is undef \$k = $k")		if ! defined $hash{$k};
		&main::quit("draw: \$hash{$k}{level} is undef")			if ! defined $hash{$k}{level};
		&main::quit("draw: \$tags{$hash{$k}{level}} is undef")	if ! defined $tags{$hash{$k}{level}};

		my $mode = $tags{$hash{$k}{level}};
		$main::log_box->insert('end', $hash{$k}{text}, $mode);
 		$main::log_box->moveTextEnd;
	}
}

sub clear
{
	%hash = ();
	$pos = 0;
	$main::log_box->Contents([]);
}

sub prune
{
	my $prune_limit = 10;
	my $count = 0;
	$main::log_box->Contents([]); # clear log box for redraw
	for my $k (sort{$a <=> $b} keys %hash)
	{
		$count++;
		delete $hash{$k};
		last if $count >= $prune_limit;

	}
	# redraw logbox
	for my $k (sort{$a <=> $b} keys %hash)
	{
		&draw($k);
	}
}

sub configure_tags
{
	# Configure log box tags with current styles
	if(defined $main::log_box)
	{
		$main::log_box->tag('configure', 'message',	
			-font=>($style::hash{message}{font} || 'TkDefaultFont'),
			-foreground=>($style::hash{message}{fgcol} || '#ffffffff'), 	
			-background=>($style::hash{message}{bgcol} || '#000000ff'));

		$main::log_box->tag('configure', 'error',	
			-font=>($style::hash{error}{font} || 'TkDefaultFont'),	
			-foreground=>($style::hash{error}{fgcol} || '#ffffffff'),	
			-background=>($style::hash{error}{bgcol} || '#ff0000ff'));

		$main::log_box->tag('configure', 'warning',	
			-font=>($style::hash{warning}{font} || 'TkDefaultFont'),	
			-foreground=>($style::hash{warning}{fgcol} || '#ffffffff'),	
			-background=>($style::hash{warning}{bgcol} || '#ff8800ff'));

		$main::log_box->tag('configure', 'info',	
			-font=>($style::hash{info}{font} || 'TkDefaultFont'),	
			-foreground=>($style::hash{info}{fgcol} || '#ffffffff'),		
			-background=>($style::hash{info}{bgcol} || '#2200ffff'));

		$main::log_box->tag('configure', 'normal');
	}
}

sub refresh
{
	# Clear and redraw log box with current styles
	if(defined $main::log_box)
	{
		# Reconfigure tags with new styles
		&configure_tags;
		
		$main::log_box->Contents([]); # clear log box for redraw
		
		# redraw all log entries with updated styles
		for my $k (sort{$a <=> $b} keys %hash)
		{
			&draw($k);
		}
	}
}

1;
