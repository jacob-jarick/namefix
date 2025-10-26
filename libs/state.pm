package state;

use strict;
use warnings;
use FindBin qw($Bin);
use Cwd;

require misc;

# return value of state $state
sub get
{
	my $state = shift;
	if(! defined $state)
	{
		&misc::plog(0, "\$state is undef", 1);
	}

	if($state eq '')
	{
		&misc::plog(0, "\$state is blank", 1);
	}

	$state = lc $state;

	return $globals::LISTING	&& $state eq 'list';
	return $globals::RUN		&& $state eq 'run';
	return $globals::STOP		&& $state eq 'stop';
	return $globals::IDLE		&& $state eq 'idle';

	# unknown state, log & exit
	&misc::plog(0, "Unknown check '$state'", 1);
}

# return 1 if we are doing something
sub busy
{
	return 1 if $globals::LISTING;
	return 1 if $globals::RUN;
	return 1 if $globals::STOP;	# if set then not idle and still in the process of stopping

	return 0 if $globals::IDLE;

	# unknown state, log & exit
	&misc::plog(0, "sub state_busy: error, unknown state\n\tLISTING: $globals::LISTING\n\tRUN: $globals::RUN\n\tSTOP: $globals::STOP\n\tIDLE: $globals::IDLE", 1);
}

# set state
sub set
{
	my $state = shift;

	if(! defined $state)
	{
		&misc::plog(0, "\$state is undef");
		return 0;
	}
	if($state eq '')
	{
		&misc::plog(0, "\$state is blank");
		return 0;
	}

	$state = lc $state;

	if ($state eq 'idle') 
	{
		# Allow transition to idle from any state (completion/cleanup)
		# This is used when finishing listing, running, or stopping operations

		$globals::IDLE 		= 1;

		$globals::LISTING	= 0;
		$globals::RUN		= 0;
		$globals::STOP		= 0;

		$globals::PREVIEW	= 1;	# always revert to preview mode when going idle

		return 1;
	} 

	if ($state eq 'list') 
	{
		if (!$globals::IDLE)
		{
			&misc::plog(0, "IDLE is not set, cannot set to 'LIST'\n\tLISTING: $globals::LISTING\n\tRUN: $globals::RUN\n\tSTOP: $globals::STOP");

			return 0;
		}

		$globals::IDLE    	= 0;
		$globals::LISTING 	= 1;
		$globals::RUN     	= 0;
		$globals::STOP    	= 0;

		$globals::PREVIEW	= 1;	# always use preview mode when listing

		return 1;
	} 

	if ($state eq 'run') 
	{
		if (!$globals::IDLE)
		{
			&misc::plog(0, "IDLE is not set, cannot set to 'RUN'\n\tLISTING: $globals::LISTING\n\tRUN: $globals::RUN\n\tSTOP: $globals::STOP");
			return 0;
		}		

		$globals::IDLE    = 0;
		$globals::LISTING = 0;
		$globals::RUN     = 1;
		$globals::STOP    = 0;

		return 1;
	} 

	if ($state eq 'stop') 
	{
		if ($globals::LISTING)
		{
			&misc::plog(1, "Forced STOP while LISTING");
		}
		if ($globals::RUN)
		{
			&misc::plog(1, "Forced STOP while RUNNING");
		}
		if ($globals::IDLE)
		{
			&misc::plog(1, "STOP requested while IDLE is set\n\tLISTING: $globals::LISTING\n\tRUN: $globals::RUN\n\tSTOP: $globals::STOP");
			return 0;
		}

		$globals::IDLE    	= 0;
		$globals::LISTING 	= 0;
		$globals::RUN     	= 0;
		$globals::STOP    	= 1; # Indicate we are in the process of stopping

		return 1;
	}

	&misc::plog(0, "sub state_set: error, unknown state '$state'");

	return 0;
}

1;