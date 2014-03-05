package main;

use lib qw( lib t/lib );
use Test::More tests=>2;
use Gear;
use AnyEvent;
use AnyEvent::Gearman;
use AnyEvent::Gearman::WorkerPool;

use Scalar::Util qw(weaken);
my $port = '9955';
my @js = ("localhost:$port");
my $cv = AE::cv;

my $t = AE::timer 10,0,sub{ $cv->send('timeout')};

use_ok('Gearman::Server');
gstart($port);

my $slotman = AnyEvent::Gearman::WorkerPool->new(
    config=>
    {
        global=>{
            job_servers=>\@js,
            libs=>['t/lib','./lib'],
            max=>3,
            },
        slots=>{
            'TestWorker'=>{}
        }
    },
    port=>55595,
);

my $tt = AE::timer 5,0,sub{ 
#    $slot->stop();
#    is $slot->is_stopped, 1;
    $cv->send;
};

my $res = $cv->recv;
isnt $res,'timeout','ends successfully';
undef($tt);
undef($slotman);
gstop();

done_testing();
