package main;

use lib './t','./lib';
use Test::More tests=>3;
use Gear;
use AnyEvent;
use AnyEvent::Gearman;
use Gearman::Slot;
use IPC::AnyEvent::Gearman;
use Scalar::Util qw(weaken);
my $port = '9955';
my @js = ("localhost:$port");
my $cv = AE::cv;

my $t = AE::timer 10,0,sub{ $cv->send('timeout')};

use_ok('Gearman::Server');
gstart($port);

my $slot = Gearman::Slot->new(
    job_servers=>\@js,
    libs=>['./t','./lib'],
    leftwork=>3,
    worker_package=>'TestWorker',
    worker_channel=>'child'
);

$slot->spawn();

my $tt = AE::timer 5,0,sub{ 
    $slot->stop();
    is $slot->is_stopped, 1;
    $cv->send;
};

my $res = $cv->recv;
isnt $res,'timeout','ends successfully';
undef($ipc);
undef($t);
undef($tt);
undef($slot);
gstop();

done_testing();
