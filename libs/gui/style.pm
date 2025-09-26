package style;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;

use Carp;

use Tk;
use Tk::Toplevel;
use Tk::FontDialog;
use Tk::ColourChooser;
use Config::IniHash;

use Data::Dumper::Concise;

our @default_styles 	= ('message', 'info', 'error', 'warning');

my $home				= &get_home;
my $config_file			= "$home/styles.ini";

my %defaults			= ();
$defaults{font}			= 'font6';
$defaults{fgcol}		= '#ffffff';
$defaults{bgcol}		= '#000000';
$defaults{underline}	= 0;

our %hash				= ();

our $main;

&load;

sub load
{
	if(-f $config_file)
	{
		my $ini	= ReadINI $config_file;
		%hash	= %{$ini};

		for my $k(keys %hash)
		{
			$hash{$k}{font}			= $defaults{font}		if ! defined $hash{$k}{font}		|| $hash{$k}{font} eq '';
			$hash{$k}{fgcol}		= $defaults{fgcol}		if ! defined $hash{$k}{fgcol}		|| $hash{$k}{fgcol} eq '';
			$hash{$k}{bgcol}		= $defaults{bgcol}		if ! defined $hash{$k}{bgcol}		|| $hash{$k}{bgcol} eq '';
			$hash{$k}{underline}	= $defaults{underline}	if ! defined $hash{$k}{underline}	|| $hash{$k}{underline} eq '';
		}
	}
	else
	{
		for my $s(@default_styles)
		{
			%{$hash{$s}} = %defaults;
		}
	}
}

sub save
{
	WriteINI ($config_file, \%hash);
}

# a style consists of: font, foreground colour, background colour, other options

sub add
{
	my $name		= shift;
	my $font		= shift;
	my $fgcol		= shift;
	my $bgcol		= shift;
	my $underline	= shift;

	%{$hash{$name}}			= %defaults;

	$hash{$name}{font}		= $font			if defined $font;
	$hash{$name}{fgcol}		= $fgcol		if defined $fgcol;
	$hash{$name}{bgcol}		= $bgcol		if defined $bgcol;
	$hash{$name}{underline}	= $underline	if defined $underline;

	&save;
	# Refresh log display with new styles
	&log::refresh;
	destroy $main;
	&display;
}

sub list
{
	my @arr = sort {lc $a cmp lc $b} keys  %hash;
	return @arr;
}

sub rm
{
	my $name = shift;
	delete $hash{$name} if defined $hash{$name};
}

sub set_font
{
	my $name	= shift;

	confess "set_font: \$name '$name' not found in \$hash" if ! defined $hash{$name};

	my $old_font = $hash{$name}{font};
	$hash{$name}{font} = $main::mw->FontDialog(-initfont => $hash{$name}{font})->Show;
	if (defined $hash{$name}{font})
	{
		$hash{$name}{font} = $main::mw->GetDescriptiveFontName($hash{$name}{font});
	}
	else
	{
		$hash{$name}{font} = $old_font;
	}

  	$hash{$name}{font} = $main::mw->GetDescriptiveFontName($hash{$name}{font});

	&add($name, $hash{$name}{font}, $hash{$name}{fgcol}, $hash{$name}{bgcol}, $hash{$name}{underline});
}

sub set_col
{
	my $name	= shift;
	my $type	= shift;

	confess "set_col: \$name '$name' not found in \$hash"	if ! defined $hash{$name};
	confess "set_col: \$type is undef"						if ! defined $type;
	confess "set_col: \$type '$type' is unknown"			if $type ne 'fgcol' && $type ne 'bgcol';

	my $col_dialog	= $main::mw->ColourChooser();
	$col_dialog	= $main::mw->ColourChooser
	(
		-title	=> "Select $type Colour",
		-colour	=> $hash{$name}{$type}
	);
	$hash{$name}{$type}	= $main::mw->chooseColor(-initialcolor=>$hash{$name}{$type});

	&add($name, $hash{$name}{font}, $hash{$name}{fgcol}, $hash{$name}{bgcol}, $hash{$name}{underline});
}

sub get_home
{
	my $home = undef;
	$home = $ENV{HOME}			if defined $ENV{HOME} && lc $^O ne 'mswin32';
	$home = $ENV{USERPROFILE}	if lc $^O eq 'mswin32';


	$home = $ENV{TMP}		if ! defined $home; # surely the os has a tmp if nothing else
	$home =~ s/\\/\//g;

	my $app_dir = "$home/.namefix.pl";

	if(!-d $app_dir)
	{
		mkdir($app_dir, 0755) or &main::quit("Cannot mkdir: '$app_dir' $!\n");
	}
	return $app_dir;
}

sub display
{
	my $row = 1;

	$main = $main::mw -> Toplevel(-title => 'Styles' );
	$main->raise;

	$main->protocol
	(
		'WM_DELETE_WINDOW',
		sub
		{
			$main->destroy;
			return;
		}
	);

	my $frame_top = $main->Frame
	(
		-height => 10,
	)->pack
	(
		-side=> 	'top',
		-expand=> 	1,
		-fill=> 	'both',
		-anchor=>	'n'
	);

	for my $name(&list)
	{
		my $col = 0;


		my $text = $frame_top -> ROText
		(
			-height=>		1,
			-width=>		20,
			-background=>	$hash{$name}{bgcol},
			-foreground=>	$hash{$name}{fgcol},
			-font=>			$hash{$name}{font},
		)
		-> grid
		(
			-row=>		$row,
			-column=>	$col++,
			-sticky=>	'nw',
			-padx=>		2
		);
		$text->Contents($name);

		$frame_top -> Button
		(
			-text=>				"Font",
			-background=>		$hash{$name}{bgcol},
			-foreground=>		$hash{$name}{fgcol},
			-font=>				$hash{$name}{font},
			-activebackground=>	'cyan',
			-command=> 			sub { &set_font($name); }
		)
		-> grid
		(
			-row=>		$row,
			-column=>	$col++,
			-sticky=>	'nw',
			-padx=>		2
		);

		$frame_top -> Button
		(
			-text=>				"FG Colour",
			-background=>		$hash{$name}{bgcol},
			-foreground=>		$hash{$name}{fgcol},
			-font=>				$hash{$name}{font},
			-activebackground=> 'cyan',
			-command=>	 		sub { &set_col($name, 'fgcol');  }
		)-> grid
		(
			-row=>		$row,
			-column=>	$col++,
			-sticky=>	'nw',
			-padx=>		2
		);
		$frame_top -> Button
		(
			-text=>				"BG Colour",
			-background=>		$hash{$name}{bgcol},
			-foreground=>		$hash{$name}{fgcol},
			-font=>				$hash{$name}{font},
			-activebackground=> 'cyan',
			-command=>			sub { &set_col($name, 'bgcol'); }
		)-> grid
		(
			-row=>		$row,
			-column=>	$col++,
			-sticky=>	'nw',
			-padx=>		2
		);
		$row++;
	}
	$frame_top -> Button
	(
		-text=>				'Close',
		-activebackground=>	'white',
		-command=>			sub { destroy $main; }
	)
	-> grid
	(
		-row=>		$row,
		-column=>	1,
		-sticky=>	'nw'
	);
}

1;
