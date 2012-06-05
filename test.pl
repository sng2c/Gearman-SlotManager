package main;

use lib './t','./lib';
use Gear;
use AnyEvent;
use AnyEvent::Gearman;
use Gearman::SlotManager;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);

use IPC::AnyEvent::Gearman;
use Scalar::Util qw(weaken);
my $port = '9955';
my @js = ("localhost:$port");

gstart($port);

my $cv = AE::cv;

my $sig = AE::signal 'INT'=> sub{ 
    DEBUG "TERM!!";
    $cv->send;
};

my $slotman = Gearman::SlotManager->new(
    config=>
    {
        global=>{
            job_servers=>\@js,
            libs=>['./t','./lib'],
            max=>3,
            },
        slots=>{
            'TestWorker'=>{
            min=>1, 
            max=>10,
            workleft=>10,
            }
        }
    }
);

$slotman->start();

my $res = $cv->recv;
undef($ipc);
undef($tt);
$slotman->stop;
undef($slotman);
gstop();

