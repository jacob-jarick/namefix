#!/usr/bin/perl
use strict;
use warnings;

# Simple test runner without Test::More dependency
my $test_count = 0;
my $pass_count = 0;

sub ok
{
    my ($condition, $description) = @_;
    $test_count++;
    if ($condition) 
	{
        print "ok $test_count - $description\n";
        $pass_count++;
        return 1;
    } 
	else 
	{
        print "not ok $test_count - $description\n";
        return 0;
    }
}

sub pass 
{
    my ($description) = @_;
    return ok(1, $description);
}

sub fail 
{
    my ($description) = @_;
    return ok(0, $description);
}

sub diag 
{
    my ($message) = @_;
    $message =~ s/^/# /mg;
    print "$message\n";
}

sub done_testing 
{
    print "1..$test_count\n";
    if ($pass_count == $test_count) 
	{
        print "# All tests passed\n";
        exit 0;
    } 
	else 
	{
        print "# " . ($test_count - $pass_count) . " test(s) failed\n";
        exit 1;
    }
}

# Test namefix.pl GUI startup and shutdown without errors
# This verifies our config refactoring didn't break the GUI

# Test 1: Check if namefix.pl file exists
ok(-f 'namefix.pl', 'namefix.pl exists');

# Test 2: Check if namefix.pl has valid Perl syntax
my $syntax_check = `perl -c namefix.pl 2>&1`;
my $syntax_exit_code = $? >> 8;

# We expect module loading errors but no syntax errors
if ($syntax_exit_code == 0) 
{
    pass('namefix.pl has valid syntax');
} 
elsif ($syntax_check =~ /Can't locate.*\.pm in \@INC/ && $syntax_check !~ /syntax error/) 
{
    pass('namefix.pl has valid syntax (missing modules expected)');
} 
else 
{
    fail('namefix.pl has syntax errors');
    diag("Syntax check output: $syntax_check");
}

# Test 3: Launch GUI with --gui-test and expect it to auto-quit
my $output = `perl namefix.pl --gui-test 2>&1`;
my $exit_code = $? >> 8;
if ($output =~ /\[GUI TEST\] Timer expired, quitting/) 
{
    pass('GUI launches and auto-quits with --gui-test');
} 
else 
{
    fail('GUI did not auto-quit as expected');
    diag("GUI output: $output");
}



done_testing();