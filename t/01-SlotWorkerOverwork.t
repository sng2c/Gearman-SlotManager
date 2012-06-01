package main;

use lib './t','./lib';
use Test::More tests=>3;
use Gear;
use AnyEvent;
use AnyEvent::Gearman;
use TestWorker;
use IPC::AnyEvent::Gearman;

my $port = '9955';
my @js = ("localhost:$port");
my $cv = AE::cv;

my $t = AE::timer 10,0,sub{ $cv->send('timeout')};

use_ok('Gearman::Server');
gstart($port);

my $w = TestWorker->new(job_servers=>\@js,cv=>$cv,pch=>undef,workleft=>2);
my $c = gearman_client @js;
my $ipc = IPC::AnyEvent::Gearman->new(job_servers=>\@js);
is $w->ipc->channel, $ipc->channel($$), 'check channel';
$c->add_task('TestWorker::reverse'=>'HELLO', on_complete=>sub{
});
$c->add_task('TestWorker::reverse'=>'HELLO', on_complete=>sub{
});



my $res = $cv->recv;
is $res,'overworked','overwork check';
undef($ipc);
undef($t);
undef($w);
undef($c);
gstop();


done_testing();
