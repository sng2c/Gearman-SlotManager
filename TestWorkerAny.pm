package TestWorkerAny;

use lib qw(./lib);
use Gearman::Manager;
use base 'Gearman::Manager::BaseWorker';
sub work_echo{
        require AnyEvent;
        require EV;
        my $self = shift;
        my $workload = shift;
        my $condvar = AnyEvent->condvar;
        my $w = AnyEvent->timer(after=>3,cb=>sub{$condvar->send;});
        


        #print "TestWorker::echo '$workload' recv\n";
        $condvar->recv;
	return $workload.' by EXEC';
}

1;
