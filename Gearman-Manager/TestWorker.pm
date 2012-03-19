package TestWorker;
use lib qw(./lib);
use Gearman::Manager;
use base 'Gearman::Manager::BaseWorker';
sub work_echo{
        my $self = shift;
        my $workload = shift;
	return $workload." by FORK";
}

1;
