package Gearman::SlotWorker;

# ABSTRACT: A worker launched by Slot

# VERSION
use namespace::autoclean;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);

use Any::Moose;
use AnyEvent;
use AnyEvent::Gearman;
use AnyEvent::Gearman::Worker::RetryConnection;
use IPC::AnyEvent::Gearman;

# options
has job_servers=>(is=>'rw',isa=>'ArrayRef', required=>1);
has cv=>(is=>'rw',required=>1);
has pch=>(is=>'rw',required=>1);
has workleft=>(is=>'rw',isa=>'Int', default=>-1);

# internal
has exported=>(is=>'ro',isa=>'ArrayRef[Class::MOP::Method]', default=>sub{[]});
has ipc=>(is=>'rw');
has worker=>(is=>'rw');

sub BUILD{
    my $self = shift;

    # register
    my $meta = $self->meta();
    my $package = $meta->{package};
    my $exported = $self->exported();

    if( $self->workleft == 0 ){
        $self->workleft(-1);
    }

    for my $method ( $meta->get_all_methods) 
    {
        my $packname = $method->package_name;
        next if( $packname eq __PACKAGE__ ); # skip base class

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

    $self->register();

    my $ipc = IPC::AnyEvent::Gearman->new(job_servers=>$self->job_servers);
    $ipc->on_recv(sub{
        my $msg = shift;
        DEBUG "recv $msg";
        if($msg eq 'exit') {
            $self->cv->send('bekilled');
        }
    });
    $ipc->listen();
    $self->ipc($ipc);
}

sub report{
    my $self = shift;
    my $msg = shift;

    if( defined($self->pch) )
    {
        DEBUG "report $msg";
        $self->ipc->send($self->pch,$msg);
    }
}

sub register{
    my $self = shift;
    my $w = gearman_worker @{$self->job_servers};
    $w = AnyEvent::Gearman::Worker::RetryConnection::patch_worker($w);
    foreach my $m (@{$self->exported}){
        DEBUG "register ".$m->fully_qualified_name;
        my $fname = $m->fully_qualified_name;
        my $fcode = $m->body;
        $w->register_function($fname =>
            sub{
                DEBUG "WORKER ". $fname;
                my $job = shift;
                my $workload = $job->workload;
                $self->report('BUSY');
                my $res;
                eval{
                    $res = $fcode->($self,$workload);
                };
                if ($@){
                    ERROR $@;
                    $job->fail;
                }
                elsif ( !defined($res) ){
                    $job->fail;
                }
                else{
                    $job->complete($res);
                }

                $self->report('IDLE');

                if( $self->workleft > 0 ){
                    $self->workleft($self->workleft-1);
                }

                if( $self->workleft == 0 ){
                    $self->cv->send('overworked');
                }
            }
        );
    }
    $self->worker($w);
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

# class member
sub Loop{
    my $class = shift;
    die 'Use like PACKAGE->Loop(%opts).' unless $class;
    die 'You need to use your own class extending '. __PACKAGE__ .'!' if $class eq __PACKAGE__;
    my %opt = @_;
    my $cv = AE::cv;

    my $worker;

    eval{
        $worker = $class->new(%opt,cv=>$cv);
    };
    die $@ if($@);

    $cv->recv;
}

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

then generally

    use AnyEvent;
    use TestWorker;
    my $cv = AE::cv;

    my $worker = TestWorker->new(job_servers=>['localhost:9998'],cv=>$cv);

    $cv->recv;

or 

    use TestWorker;
    TestWorker->Loop(job_servers=>['localhost:9998']);

or in shell

    perl -MTestWorker -e 'TestWorker->Loop(job_servers=>["localhost:9998"])'

You can see only 'reverse'

=cut

