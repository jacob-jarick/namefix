
sub undo_gui
{
	&plog(3, "sub undo_gui:");
	my $title = "Undo GUI";
	my @a = @main::undo_cur;
	my @b = @main::undo_pre;
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
        -> grid
	(
        	-row => $row++,
        	-column => 1,
        	-columnspan => 2
        );

        $top -> Button
	(
        	-text=>"Preform Undo",
        	-activebackground => "white",
        	-command => sub 
		{
        		&undo_rename;
        		destroy $top;
        		&ls_dir;
        	}
        )
        -> grid
	(
        	-row => $row,
        	-column => 1,
        	-columnspan => 1
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
        -> grid
	(
        	-row => $row++,
        	-column => 2,
        	-columnspan => 1
        );

#	$top->resizable(0,0);

	# --------------------------------
	# Gui drawn, add contents
	
	$hlist->header('create', 0, -text =>'Current Filename');
	$hlist->header('create', 1, -text =>'->');
	$hlist->header('create', 2, -text =>'Previous Filename');


	$c = 0;
	for(@a)
	{
		$hlist->add
		(
			$c
		);
		$hlist->itemCreate($c, 0, -text => "$_");
		$hlist->itemCreate($c, 1, -text => " -> ");
		$hlist->itemCreate($c, 2, -text => "$b[$c]");
		$c++;
	}
	return 1;
}



1;