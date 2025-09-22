package br_preview;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;

#--------------------------------------------------------------------------------------------------------------
# br_preview
#--------------------------------------------------------------------------------------------------------------

sub preview
{
	&run_namefix::prep_globals;

	my $ref1 = shift;
	my $ref2 = shift;

	my @new_l = @$ref1;
	my @old_l = @$ref2;

	&main::quit("preview: \$ref1 is undef")		if ! defined $ref1;
	&main::quit("preview: \$ref2 is undef")		if ! defined $ref2;
	&main::quit("preview: \@new_l is undef")	if ! @new_l;
	&main::quit("preview: \@old_l is undef")	if ! @old_l;
	&main::quit("preview: scalar \@new_l = 0")	if scalar @new_l == 0;
	&main::quit("preview: scalar \@old_l = 0")	if scalar @old_l == 0;

	if(scalar @new_l != scalar @old_l)
	{
		&misc::plog(0, "preview: new list length != old list length");
		return;
	}

	my @new_a = ();
	my @new_b = ();

	for my $c(0 .. $#new_l)
	{
		my $of = $old_l[$c];
		my $nf = $new_l[$c];
		$nf =~ s/\n|\r//g;
		$of =~ s/\n|\r//g;

		if($nf eq '') # return when we hit a blank line, else we risk zero'ing the rest of the filenames
		{
			&misc::plog(0, "preview: line ".($c+1).": error no string for new filename, aborting preview");
			return;
		}

		next if $of eq $nf;

		&misc::plog(3, "preview: '$of' -> '$nf'");
		push @new_a, $of;
		push @new_b, $nf;
	}
	&br_show_lists('BR Preview', \@new_a, \@new_b);
	return 1;
}

#--------------------------------------------------------------------------------------------------------------
# br_preview_list
#--------------------------------------------------------------------------------------------------------------

sub br_show_lists
{
	&misc::plog(3, "sub br_preview_list");
	my $title	= shift;
	my $aref	= shift;
	my $bref	= shift;

	my @new_a	= @$aref;
	my @new_b	= @$bref;

	my $row		= 0;
	my $col		= 0;

	# -----------------------
	# start drawing gui

        my $top = $main::mw -> Toplevel();
        $top->title($title);

        my $hlist = $top->Scrolled
        (
		'HList',
		-scrollbars=>		'osoe',
		-header=>		1,
		-columns=>		3,
		-selectbackground=>	'Cyan',
		-width=>		80,
	)
        ->pack
	(
		-side=>'top',
		-fill=>'both',
		-expand=>1,
        );

        $top->Button
	(
        	-text=>			'Close',
        	-activebackground=>	'white',
        	-command=>		sub { destroy $top; }
        )
        ->pack(-side=>'bottom');

	# --------------------------------
	# Gui drawn, add contents

	$hlist->header('create', 0, -text =>'Old Filename');
	$hlist->header('create', 1, -text =>'->');
	$hlist->header('create', 2, -text =>'New Filename');

	for my $c(0..$#new_a)
	{
		$hlist->add($c);
		$hlist->itemCreate($c, 0, -text => $new_a[$c]);
		$hlist->itemCreate($c, 1, -text => ' -> ');
		$hlist->itemCreate($c, 2, -text => $new_b[$c]);
		$c++;
	}
}

1;
