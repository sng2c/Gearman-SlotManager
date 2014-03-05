package main;

use lib qw( lib t/lib );
use Test::More tests=>3;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);
use Gear;
use AnyEvent;
use AnyEvent::Gearman;
use AnyEvent::Gearman::WorkerPool::Slot;
use Scalar::Util qw(weaken);
my $port = '9955';
my @js = ("localhost:$port");
my $cv = AE::cv;

my $t = AE::timer 10,0,sub{ $cv->send('timeout')};

use_ok('Gearman::Server');
gstart($port);

my $slot = AnyEvent::Gearman::WorkerPool::Slot->new(
    job_servers=>\@js,
    libs=>['t/lib','./lib'],
    workleft=>3,
    worker_package=>'TestWorker',
    worker_channel=>'child',
);

$slot->start();

my $tt = AE::timer 5,0,sub{ 
    $slot->stop();
    is $slot->is_stopped, 1;
    $cv->send;
};

my $res = $cv->recv;
isnt $res,'timeout','ends successfully';
undef($t);
undef($tt);
undef($slot);
gstop();

done_testing();
