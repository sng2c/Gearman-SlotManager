#!/usr/bin/perl
use strict;
use lib qw(. ./lib);
use Gearman::Manager;
use Storable qw(thaw);
use Data::Dumper;
use JSON;
print "----------------------\n";
print "type:EXEC @ARGV\n";
print "----------------------\n";

my $class = $ARGV[0];
my $slot = $ARGV[1];
my $conf = from_json($ARGV[2]);

my $proc = Gearman::Manager::_fork_proc($class,$conf,$slot);
$proc->();

