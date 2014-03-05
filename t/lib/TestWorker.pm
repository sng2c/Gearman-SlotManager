package TestWorker;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);

use Moose;

extends 'AnyEvent::Gearman::WorkerPool::Worker';

sub slowreverse{
    my $self = shift;
    my $data = shift;
    sleep(1);
    return reverse($data);
}
sub reverse{
    my $self = shift;
    my $data = shift;

    return reverse($data);
}
sub _private{
    my $self = shift;
    my $data = shift;
    DEBUG "_private:".$data;
}

1;
