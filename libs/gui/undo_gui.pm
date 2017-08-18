package undo_gui;
require Exporter;
@ISA = qw(Exporter);

sub display
{
	my $row		= 0;
	my $col		= 0;

        my $top = $main::mw -> Toplevel();
        $top -> title('Undo GUI');

        my $hlist = $top -> Scrolled
        (
		"HList",
		-scrollbars=>'osoe',
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
        	-text=>'Preform Undo',
        	-activebackground => 'white',
        	-command => sub
		{
        		&undo::undo_rename;
        		&dir::ls_dir;
        		destroy $top;
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
        	-text=>'Close',
        	-activebackground => 'white',
        	-command => sub { destroy $top; }
        )
        -> grid
	(
        	-row => $row++,
        	-column => 2,
        	-columnspan => 1
        );

	$hlist->header('create', 0, -text =>'Current Filename');
	$hlist->header('create', 1, -text =>'->');
	$hlist->header('create', 2, -text =>'Previous Filename');

	$top->resizable(0,0);

	# Gui drawn, add contents
	for my $c (0 .. $#config::undo_cur)
	{
		$hlist->add($c);
		$hlist->itemCreate($c, 0, -text => $config::undo_cur[$c]);
		$hlist->itemCreate($c, 1, -text => ' -> ');
		$hlist->itemCreate($c, 2, -text => $config::undo_pre[$c]);
		$c++;
	}
	return 1;
}

1;
