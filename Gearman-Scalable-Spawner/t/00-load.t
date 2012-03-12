#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Gearman::Scalable::Spawner' ) || print "Bail out!\n";
}

diag( "Testing Gearman::Scalable::Spawner $Gearman::Scalable::Spawner::VERSION, Perl $], $^X" );
