package Gearman::SlotWorker;

# ABSTRACT: A worker launched by Slot

# VERSION

use namespace::autoclean;
use Any::Moose;

use AnyEvent;
use AnyEvent::Gearman;
use IPC::AnyEvent::Gearman;
use AnyEvent::Gearman::Worker::RetryConnection;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);


has exported=>(is=>'ro',isa=>'ArrayRef[Class::MOP::Method]', default=>sub{[]});
has maxwork=>(is=>'rw',isa=>'Int');

sub BUILD{
    my $self = shift;

    my $meta = $self->meta();
    my $package = $meta->{package};
    my $exported = $self->exported();

    for my $method ( $meta->get_all_methods) 
    {
        my $packname = $method->package_name;
        my $methname = $method->name;
        if( $packname eq $package )
        {
            if( $methname !~ /^_/ && $methname ne uc($methname) && $methname ne 'meta' )
            {
                if( !$meta->has_attribute($methname) ){
                    DEBUG 'filtered: '.$method->fully_qualified_name;
                    push(@{$exported},$method);
                }
            }
        }
    }
}

sub report{
}

sub start_worker{
    my $class = shift;
    my %opt = @_;
    die 'Needs job_servers. Call as start_worker($maxcount, @job_servers)' unless @{$opt->{job_servers}};
    my $worker = $class->new(%opt);
   
    DEBUG "AnyEventModel=>".AnyEvent::detect;
    my $cv = AE::cv;

    my $w = gearman_worker @{$opt->{job_servers}};
    $w = AnyEvent::Gearman::Worker::RetryConnection::patch_worker($w);

    foreach my $m (@{$worker->exported}){
        DEBUG "register ".$m->fully_qualified_name;
        my $fname = $m->fully_qualified_name;
        my $fcode = $m->body;
        $w->register_function($fname =>
        sub{
            DEBUG "WORKER ". $fname;
            my $job = shift;
            my $workload = $job->workload;
            my $res = $fcode->($worker,$workload);
            $job->complete($res);

            if( $worker->maxcount > 0 ){
                $worker->maxcount($worker->maxcount-1);
                if( $worker->maxcount == 0 ){
                    $cv->send;
                }
            }
        });
    }

    $cv->recv;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 SYNOPSIS

make TestWorker.pm

    package TestWorker;
    use Any::Moose;
    extends 'Gearman::SlotWorker';

    sub reverse{ # will be registered as function 'TestWorker::reverse'
        my $self = shift;
        my $data = shift;
        return reverse($data);
    }

    sub _private{  # not care leading '_'
        my $self = shift;
        my $data = shift;
        return $data;
    }

    sub NOTVISIBLE{ # not care all-uppercase
        #...
    }

then run as below in shell

    perl -MTestWorker -e 'start_worker("localhost:9998")'

You can see only 'reverse'

=cut

