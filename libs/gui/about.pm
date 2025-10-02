package about;
require Exporter;
@ISA = qw(Exporter);

use strict;
use warnings;

#--------------------------------------------------------------------------------------------------------------
# Show about box
#--------------------------------------------------------------------------------------------------------------

sub show_about
{
	my $help_text = join('', &misc::readf($globals::about));

	my $row = 1;
        my $top = $main::mw -> Toplevel();
        $top -> title('About');

	# Tiered fallback system for image loading
	# Tier 1: Try Tk::JPEG (preferred)  
	# Tier 2: Try PPM fallback (converted image)
	# Tier 3: Text fallback (no image)
	my $image;
	my $fallback_method = "none";
	
	# Tier 1: Try JPEG if available
	if ($main::HAS_JPEG) 
	{
		eval 
		{
			$image = $main::mw->Photo
			(
				-format=>	'jpeg',
				-file=>		$globals::mempic
			);
		};
		if (!$@ && $image) 
		{
			$fallback_method = "jpeg";
		} 
		else 
		{
			undef $image;
		}
	}
	
	# Tier 2: Try PPM fallback if JPEG failed or unavailable
	if (!$image) 
	{
		my $ppm_path = $globals::mempic;
		$ppm_path =~ s/\.jpg$/.ppm/i;
		
		eval 
		{
			$image = $main::mw->Photo
			(
				-format=>'ppm',
				-file=>$ppm_path
			);
		};

		if (!$@ && $image) 
		{
			$fallback_method = "ppm";
		} 
		else 
		{
			undef $image;
		}
	}
	
	if ($image) 
	{
		$top->Label
		(
			-image=>$image
		)
		-> grid
		(
			-row=>		2,
			-column=>	1
		);
	} 
	else 
	{
		# Tier 3: Text fallback when both image methods fail
		$fallback_method = "text";
		$top->Label
		(
			-text=>		"[Green mohawk photo unavailable]\n(But the wild creativity lives on!)\n\nImage display not available",
			-font=>		$config::dialog_font,
			-justify=>	'center',
			-fg=>		'darkblue',
			-relief=>	'sunken',
			-padx=>		10,
			-pady=>		10
		)
		-> grid
		(
			-row=>		2,
			-column=>	1
		);
	}

	# Log the fallback method used
	if ($fallback_method eq 'ppm') 
	{
		&misc::plog(2, "about.pm: Using PPM fallback for image display (Tk::JPEG not available)");
	} 
	elsif ($fallback_method eq 'text') 
	{
		&misc::plog(2, "about.pm: Using text fallback for image display (no image support available)");
	}

	my $txt = $top -> Scrolled
	(
		'ROText',
		-scrollbars=>	'osoe',
		-wrap=>		'word',
		-font=>		$config::dialog_font,
		-width=>	60,
		-height=>	18
	)
	-> grid
	(
		-row=>		2,
		-column=>	2
	);

	$txt->menu(undef);
	$txt->insert
	(
		'end',
		$help_text
	);

	$top->Button
	(
		-text=>				'Close',
		-activebackground=>	'cyan',
		-command=> 
		sub
		{
			destroy $top;
		}
	)
	-> grid
	(
		-row=>			4,
		-column=>		1,
		-columnspan=>	2
	);

	$top->update();
	$top->resizable(0,0);
}

1;
