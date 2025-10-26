package state;

use strict;
use warnings;
use FindBin qw($Bin);
use Cwd;

require misc;



# return 1 if state matches argument
sub check
{
	my $check = shift;
	if(! defined $check)
	{
		&misc::plog(0, "\$check is undef");
		return 0;
	}
	if($check eq '')
	{
		&misc::plog(0, "\$check is blank");
		return 0;
	}

	return 1 if $globals::LISTING	&& $check eq 'list';
	return 1 if $globals::RUN		&& $check eq 'run';
	return 1 if $globals::STOP		&& $check eq 'stop';
	return 1 if $globals::IDLE		&& $check eq 'idle';

	# Check if it's a valid state but the flag is just false
	if ($check eq 'stop' || $check eq 'list' || $check eq 'run' || $check eq 'idle') 
	{
		return 0;  # Valid state, but flag is false
	}

	# unknown state, log & exit
	&misc::plog(0, "Unknown check '$check'", 1);
}

# get current state as string
sub get
{
	my $state = shift;
	return $globals::STOP		if $state eq 'stop';
	return $globals::LISTING	if $state eq 'list';
	return $globals::RUN		if $state eq 'run';
	return $globals::IDLE		if $state eq 'idle';

	&misc::plog(0, "Unknown state\n\tLISTING: $globals::LISTING\n\tRUN: $globals::RUN\n\tSTOP: $globals::STOP\n\tIDLE: $globals::IDLE");

	return "unknown state '$state'";
}

# return 1 if we are doing something
sub busy
{
	return 1 if $globals::LISTING;
	return 1 if $globals::RUN;
	return 1 if $globals::STOP;	# if set then not idle and still in the process of stopping

	return 0 if $globals::IDLE;
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
		
		$globals::IDLE    = 1;

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

		$globals::IDLE    = 0;
		$globals::LISTING = 1;
		$globals::RUN     = 0;
		$globals::STOP    = 0;

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