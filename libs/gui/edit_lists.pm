use strict;
use warnings;

#--------------------------------------------------------------------------------------------------------------
# Edit Word Casing List Dialog
#--------------------------------------------------------------------------------------------------------------

sub edit_cas_list 
{
        my $dtext = "";

        if(-f $main::casing_file) 
        {
                $dtext = &readjf("$main::casing_file");
        } else 
        {
                $dtext = join("\n", @main::word_casing_arr);
        }

        my $top = $main::mw -> Toplevel();
        $top -> title
        (
        	"Edit Word Casing List"
        );

        my $txt = $top -> Scrolled
        (
        	'Text',
                -scrollbars=>"osoe",
                -width=>60,
                -height=>20,
        	-font=>$main::dialog_font
        )
        -> grid
        (
        	-row => 2,
        	-column => 1,
        	-columnspan => 2
        );
        $txt->menu(undef);

        $txt -> insert
        (
        	'end',
        	"$dtext"
        );

        my $but_save = $top -> Button
        (
        	-text=>"Save",
        	-activebackground => 'white',
        	-command => sub 
        	{
        		\&save_file
        		(
        			"$main::casing_file",
        			$txt -> get('0.0', 'end')
        		);
        	}
        )
        -> grid
        (
        	-row => 4,
        	-column => 1,
        	-sticky=>"ne"
        );

        my $but_close = $top -> Button
        (
        	-text=>"Close",
        	-activebackground => 'white',
        	-command => sub {
        		destroy $top;
        	}
        )
        -> grid
        (
        	-row => 4,
        	-column => 2,
        	-sticky=>"nw"
        );

	$top->resizable(0,0);
}


#--------------------------------------------------------------------------------------------------------------
# Edit Kill Word List Dialog
#--------------------------------------------------------------------------------------------------------------

sub edit_word_list 
{
        my $dtext = "";

        if(-f $main::killwords_file) 
        {
                $dtext = &readsjf("$main::killwords_file");
        } 
	else 
        {
                $dtext = join("\n", sort @main::kill_words_arr);
        }

        my $top = $main::mw -> Toplevel();
        $top -> title("Edit Kill Word List");

        my $txt = $top -> Scrolled
        (
        	'Text',
                -scrollbars=>'osoe',
        	-font=>$main::dialog_font,
                -width=>60,
                -height=>20,

        )
        -> grid
        (
        	-row => 2,
        	-column => 1,
        	-columnspan => 2
        );
        $txt->menu(undef);

        $txt -> insert('end', "$dtext");

        my $but_save = $top -> Button
        (
        	-text=>"Save",
        	-activebackground => 'white',
        	-command => sub 
        	{
        		\&save_file("$main::killwords_file",
        		$txt -> get('0.0', 'end'));
        	}
        )
        -> grid
        (
        	-row => 4,
        	-column => 1,
        	-sticky=>"ne"
        );

        my $but_close = $top -> Button
        (
        	-text=>"Close",
        	-activebackground => 'white',
        	-command => sub 
        	{
        		destroy $top;
        	}
        )
        -> grid
        (
        	-row => 4,
        	-column => 2,
        	-sticky=>"nw"
        );

        $top->resizable(0,0);
}


#--------------------------------------------------------------------------------------------------------------
# Edit Pattern List Dialog
#--------------------------------------------------------------------------------------------------------------

sub edit_pat_list 
{
        my $dtext = "";

        if(-f $main::killpat_file) 
        {
                $dtext = &readsjf("$main::killpat_file");
        } else 
        {
                $dtext = join("\n", sort @main::kill_patterns_arr);
        }

        my $top = $main::mw -> Toplevel();
        $top -> title("Edit Kill Pattern List");

        my $txt = $top -> Scrolled
        (
        	'Text',
                -scrollbars=>'osoe',
        	-width=>45,
        	-height=>10,
        	-font=>$main::edit_pat_font
        )
        -> grid
        (
        	-row=>2,
        	-column=>1,
        	-columnspan=>2
        );
        $txt->menu(undef);

        $txt -> insert('end', "$dtext");

        my $but_save = $top -> Button
        (
        	-text=>"Save",
        	-activebackground => 'white',
        	-command => sub 
        	{
        		\&save_file(
        			"$main::killpat_file",
        			$txt -> get('0.0', 'end')
        		);
        	}
        )
        -> grid(
        	-row => 4,
        	-column => 1,
        	-sticky=>"ne"
        );

        my $but_close = $top -> Button(
        	-text=>"Close",
        	-activebackground => 'white',
        	-command => sub {
        		destroy $top;
        	}
        )
        -> grid(
        	-row => 4,
        	-column => 2,
        	-sticky=>"nw"
        );

        $top->resizable(0,0);
}


1;