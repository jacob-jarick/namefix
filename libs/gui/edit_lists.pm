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

	if(-f $config::casing_file)
	{
		$dtext = &misc::readjf("$config::casing_file");
	} else
	{
		$dtext = join("\n", @config::word_casing_arr);
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
			&misc::save_file("$config::casing_file", $txt->get('0.0', 'end'));
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

	if(-f $config::killwords_file)
	{
		$dtext = &misc::readsjf("$config::killwords_file");
	}
	else
	{
		$dtext = join("\n", sort @config::kill_words_arr);
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
			&misc::save_file("$config::killwords_file", $txt->get('0.0', 'end')); 
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

	if(-f $config::killpat_file)
	{
		$dtext = &misc::readsjf($config::killpat_file);
	}
	else
	{
		$dtext = join("\n", sort @config::kill_patterns_arr);
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
			&misc::save_file( "$config::killpat_file", $txt->get('0.0', 'end') ); 
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
