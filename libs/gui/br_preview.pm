#--------------------------------------------------------------------------------------------------------------
# br_preview
#--------------------------------------------------------------------------------------------------------------

sub br_preview
{
	&plog(3, "sub br_preview");
	&prep_globals;

	my @new_l = split(/\n/, $main::txt_r -> get('1.0', 'end'));
	my @old_l = split(/\n/, $main::txt -> get('1.0', 'end'));

	my $c = 0;
	my $of = "";	# old file
	my $nf = "";	# new file
	my $max = $#new_l;
	my @a = ();
	my @b = ();

	while($c <= $max)
	{
		$of = $old_l[$c];
		$nf = $new_l[$c];
		$nf =~ s/\n|\r//g;
		$of =~ s/\n|\r//g;

		&plog(4, "sub br_preview: processing \"$of\" \"$nf\" ");
		
		if(!$nf) # return when we hit a blank line, else we risk zero'ing the rest of the filenames
		{
			&plog(0, "sub br_preview: error no string for new filename");
			return;
		}

		$nf = &br_ed2k_cleanup($nf);
		if($of ne $nf)
		{
			&plog(4, "sub br_preview preview rename:\n\t\"$of\"\n\t\"$nf\"");
			push @a, $of;
			push @b, $nf;
		}
		else
		{
			&plog(4, "sub br_preview no changes to \"$of\"");
		}
		$c++;
	}
	&br_show_lists("BR Preview", \@a, \@b);
	return 1;
}


#--------------------------------------------------------------------------------------------------------------
# br_preview_list 
#--------------------------------------------------------------------------------------------------------------

sub br_show_lists
{
	&plog(3, "sub br_preview_list");
	my $title = shift;
	my $a = shift;
	my $b = shift;
	
	@a = @$a;
	@b = @$b;
	
	my $row = 0;
	my $col = 0;
	my $c = 0;
	
	# -----------------------
	# start drawing gui
	
        my $top = $main::mw -> Toplevel();
        $top -> title("$title");

	# hlist here
	
        my $hlist = $top -> Scrolled
        (
		"HList",
		-scrollbars=>"osoe",
		-header => 1,
		-columns=>3,
		-selectbackground => 'Cyan',
		-width=>80,
		
	)
        -> pack
	(
		-side=>"top",
		-fill=>"both",
		-expand=>1,
        );

        $top -> Button
	(
        	-text=>"Close",
        	-activebackground => "white",
        	-command => sub 
		{
        		destroy $top;
        	}
        )
        -> pack
	(
		-side=>"bottom",
        );

#	$top->resizable(0,0);

	# --------------------------------
	# Gui drawn, add contents
	
	$hlist->header('create', 0, -text =>'Old Filename');
	$hlist->header('create', 1, -text =>'->');
	$hlist->header('create', 2, -text =>'New Filename');


	$c = 0;
	for(@a)
	{
		$hlist->add
		(
			$c
		);
		$hlist->itemCreate($c, 0, -text => $_);
		$hlist->itemCreate($c, 1, -text => " -> ");
		$hlist->itemCreate($c, 2, -text => "$b[$c]");
		$c++;
	}
}

1;