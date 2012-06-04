package main;

use lib './t','./lib';
use Test::More tests=>5;
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
    workleft=>1,
    worker_package=>'TestWorker',
    worker_channel=>'child'
);

$slot->spawn();

my $cpid = $slot->worker_pid;


#my $ttt;
#my $tt = AE::timer 5,0,sub{ 
#    $slot->stop();
#    is $slot->is_stopped, 1;
#    $ttt = AE::timer 2,0,sub{$cv->send;};
#};

my $c = gearman_client @js;
my $ipc = IPC::AnyEvent::Gearman->new(job_servers=>\@js);
$c->add_task('TestWorker::reverse'=>'HELLO', on_complete=>sub{
    my $job = shift;
    my $res = shift;
    is $res,'OLLEH','client result ok';

    $c->add_task('TestWorker::reverse'=>'HELLO', on_complete=>sub{
        my $job = shift;
        my $res = shift;
        is $res,'OLLEH','client result ok';

        isnt $slot->worker_pid, $cpid,'worker overworked';
        $slot->stop();
        $cv->send;
    });
});

my $res = $cv->recv;
isnt $res,'timeout','ends successfully';
undef($ipc);
undef($t);
undef($w);
undef($c);
undef($slot);
gstop();

done_testing();
