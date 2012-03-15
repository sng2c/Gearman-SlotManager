package TestWorker;
use lib qw(./lib);
use Gearman::Manager;
use base 'Gearman::Manager::BaseWorker';
sub echo{
        my $self = shift;
        my $workload = shift;
	return $workload;
}
sub echoany{
        require AnyEvent;
        my $self = shift;
        my $workload = shift;
        my $condvar = AnyEvent->condvar;

        my $w = AnyEvent->timer(after=>3,cb=>sub{$condvar->send;});
        


        #print "TestWorker::echo '$workload' recv\n";
        $condvar->recv;
	return $workload;
}

1;
