package main;

use lib './t','./lib';
use Test::More tests=>2;
use Gear;
use AnyEvent;
use AnyEvent::Gearman;
use TestWorker;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($ERROR);

my $port = '9955';
my @js = ("localhost:$port");
my $cv = AE::cv;

my $t = AE::timer 10,0,sub{ $cv->send('timeout')};

use_ok('Gearman::Server');
gstart($port);

my $w = TestWorker->new(job_servers=>\@js,cv=>$cv,parent_channel=>undef,channel=>'test',workleft=>2);
my $c = gearman_client @js;
$c->add_task('TestWorker::reverse'=>'HELLO', on_complete=>sub{
});
$c->add_task('TestWorker::reverse'=>'HELLO', on_complete=>sub{
});



my $res = $cv->recv;
is $res,'overworked','overwork check';
undef($t);
undef($w);
undef($c);
gstop();


done_testing();
