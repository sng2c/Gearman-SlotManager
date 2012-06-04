package main;

use lib './t','./lib';
use Test::More tests=>3;
use Gear;
use AnyEvent;
use AnyEvent::Gearman;
use Gearman::SlotManager;

use IPC::AnyEvent::Gearman;
use Scalar::Util qw(weaken);
my $port = '9955';
my @js = ("localhost:$port");
my $cv = AE::cv;

my $t = AE::timer 10,0,sub{ $cv->send('timeout')};

use_ok('Gearman::Server');
#gstart($port);

my $slotman = Gearman::SlotManager->new(
    config=>
    {
        global=>{job_servers=>\@js,libs=>['./t','./lib']},
        slots=>{'TestWorker'=>{}}
    }
);

=pod
my $tt = AE::timer 5,0,sub{ 
    $slot->stop();
    is $slot->is_stopped, 1;
    $cv->send;
};
=cut

my $res = $cv->recv;
isnt $res,'timeout','ends successfully';
undef($ipc);
undef($tt);
undef($slotman);
#gstop();

done_testing();
