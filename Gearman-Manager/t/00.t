package TestWorker;
use namespace::autoclean;
use lib './t';
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);

use Any::Moose;

extends 'Gearman::SlotWorker';

sub workmethod{
    my $self = shift;
    my $data = shift;
    DEBUG "workmethod:".$data;
    return "HELLO";
}
sub reverse{
    my $self = shift;
    my $data = shift;
    DEBUG "work:".$data;
    return reverse($data);
}
sub _private{
    my $self = shift;
    my $data = shift;
    DEBUG "_private:".$data;
}

package main;
use Test::More tests=>2;
use Gear;
use AnyEvent;

my $cv = AE::cv;

my $t = AE::timer 5,0,sub{ok('AE'); $cv->send};

use_ok('Gearman::Server');
gstart();

TestWorker->test_worker('localhost:9998');

$cv->recv;
undef($t);
gstop();

done_testing();
