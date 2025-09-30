#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use File::Find;

# Test all modules in libs directory for syntax and standards compliance

my @modules;
find
(
	sub
	{
		return unless /\.pm$/;
		push @modules, $File::Find::name;
	}, 
	"$Bin/../libs"
);

plan tests => scalar(@modules) * 3;  # 3 tests per module: syntax, package, ending

foreach my $module (sort @modules)
{
    my $rel_path = $module;
    $rel_path =~ s{.*/libs/}{libs/};

    # Test 1: Valid Perl syntax
    my $syntax_output = `perl -c "$module" 2>&1`;
    my $syntax_exit = $? >> 8;
    if ($syntax_exit == 0)
    {
        pass("$rel_path has valid syntax");
    }
    elsif ($syntax_output =~ /Can't locate.*\.pm in \@INC/ && $syntax_output !~ /syntax error/)
    {
        pass("$rel_path has valid syntax (missing dependencies expected)");
    }
    else
    {
        fail("$rel_path has syntax errors");
        diag("Syntax check output: $syntax_output");
    }

    # Test 2: Has package declaration
    open my $fh, '<', $module or fail("$rel_path cannot be opened"), next;
    my $content = do { local $/; <$fh> };
    close $fh;

    if ($content =~ /^\s*package\s+\w+(?:::\w+)*\s*;/m)
    {
        pass("$rel_path has package declaration");
    }
    else
    {
        fail("$rel_path missing package declaration");
    }

    # Test 3: Ends with 1;
    if ($content =~ /\n\s*1\s*;\s*$/)
    {
        pass("$rel_path ends with '1;'");
    }
    else
    {
        fail("$rel_path does not end with '1;'");
    }
}

exit;