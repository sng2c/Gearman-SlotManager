package TestWorker;
use lib qw(./lib);
use base 'Gearman::Manager::BaseWorker';

sub echo{
        my $self = shift;
        my $workload = shift;
        print "TestWorker::echo '$workload' recv\n";
	return $workload;
}
1;
