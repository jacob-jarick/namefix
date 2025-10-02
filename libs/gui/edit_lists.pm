package edit_lists;
require Exporter;
@ISA = qw(Exporter);


use strict;
use warnings;

#--------------------------------------------------------------------------------------------------------------
# Edit Word Casing List Dialog
#--------------------------------------------------------------------------------------------------------------

sub cas_list
{
	my $dtext = "";

	if(-f $globals::casing_file)
	{
		$dtext = &misc::readjf("$globals::casing_file");
	} else
	{
		$dtext = join("\n", @globals::word_casing_arr);
	}

	my $top = $main::mw->Toplevel();
	$top->title("Edit Word Casing List");

	my $txt = $top->Scrolled
	(
		'Text',
		-scrollbars=>	'osoe',
		-width=>		60,
		-height=>		20,
		-font=>			$config::dialog_font
	)
	->grid
	(
		-row=>			2,
		-column=>		1,
		-columnspan=>	2
	);
	$txt->menu(undef);

	$txt->insert
	(
		'end',
		"$dtext"
	);

	my $but_save = $top->Button
	(
		-text=>				"Save",
		-activebackground=>	'white',
		-command=>
		sub 
		{
			&misc::save_file("$globals::casing_file", $txt->get('0.0', 'end'));
		}
	)
	->grid
	(
		-row=>		4,
		-column=>	1,
		-sticky=>	"ne"
	);

	my $but_close = $top->Button
	(
		-text=>				"Close",
		-activebackground=>	'white',
		-command=>			sub { destroy $top; }
	)
	->grid
	(
		-row=>		4,
		-column=>	2,
		-sticky=>	"nw"
	);

	$top->resizable(0,0);
}

#--------------------------------------------------------------------------------------------------------------
# Edit Kill Word List Dialog
#--------------------------------------------------------------------------------------------------------------

sub word_list
{
	my $dtext = "";

	if(-f $globals::killwords_file)
	{
		$dtext = &misc::readsjf("$globals::killwords_file");
	}
	else
	{
		$dtext = join("\n", sort @globals::kill_words_arr);
	}

	my $top = $main::mw->Toplevel();
	$top->title("Edit Kill Word List");

	my $txt = $top->Scrolled
	(
		'Text',
		-scrollbars=>	'osoe',
		-font=>			$config::dialog_font,
		-width=>		60,
		-height=>		20,
	)
	->grid
	(
		-row=>			2,
		-column=>		1,
		-columnspan=>	2
	);
	$txt->menu(undef);

	$txt->insert('end', "$dtext");

	my $but_save = $top->Button
	(
		-text=>				"Save",
		-activebackground=>	'white',
		-command=> 
		sub 
		{ 
			&misc::save_file("$globals::killwords_file", $txt->get('0.0', 'end')); 
		}
	)
	->grid
	(
		-row=>		4,
		-column=>	1,
		-sticky=>	"ne"
	);

	my $but_close = $top->Button
	(
		-text=>				"Close",
		-activebackground=>	'white',
		-command=>			sub { destroy $top; }
	)
	->grid
	(
		-row=>		4,
		-column=>	2,
		-sticky=>	"nw"
	);

	$top->resizable(0,0);
}

#--------------------------------------------------------------------------------------------------------------
# Edit Pattern List Dialog
#--------------------------------------------------------------------------------------------------------------

sub pat_list
{
	my $dtext = "";

	if(-f $globals::killpat_file)
	{
		$dtext = &misc::readsjf($globals::killpat_file);
	}
	else
	{
		$dtext = join("\n", sort @globals::kill_patterns_arr);
	}

	my $top = $main::mw->Toplevel();
	$top->title("Edit Kill Pattern List");

	my $txt = $top->Scrolled
	(
		'Text',
		-scrollbars=>	'osoe',
		-width=>		45,
		-height=>		10,
		-font=>			$config::edit_pat_font
	)
	->grid
	(
		-row=>			2,
		-column=>		1,
		-columnspan=>	2
	);
	$txt->menu(undef);

	$txt->insert('end', "$dtext");

	my $but_save = $top->Button
	(
		-text=>				'Save',
		-activebackground=>	'white',
		-command=>
		sub 
		{
			&misc::save_file( "$globals::killpat_file", $txt->get('0.0', 'end') ); 
		}
	)
	->grid
	(
		-row=>		4,
		-column=>	1,
		-sticky=>	'ne'
	);

	my $but_close = $top->Button
	(
		-text=>				'Close',
		-activebackground=>	'white',
		-command=>			sub { destroy $top; }
	)
	->grid
	(
		-row=>		4,
		-column=>	2,
		-sticky=>	'nw'
	);

	$top->resizable(0,0);
}

1;
