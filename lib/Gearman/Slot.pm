package Gearman::Slot;

# ABSTRACT: Slot class
# VERSION
use namespace::autoclean;
use Any::Moose;
use AnyEvent;
use Gearman::SlotWorker;
use IPC::AnyEvent::Gearman;

has id=>(is=>'ro',default=>sub{time});
has job_servers=>(is=>'rw',isa='ArrayRef',required=>1);
has pch=>(is=>'rw',required=>1);

has cv=>(is=>'rw',required=>1);
has worker_package=>(is=>'rw');
has worker_ipc=>(is=>'rw', isa=>'');
has ipc=>(is=>'rw');
has is_busy=>(is=>'rw');

sub BUILD{
    my $self = shift;
    $self->ipc( IPC::AnyEvent::Gearman->new(job_servers=>$self->job_servers));
    $self->ipc->listen;
    $self->ipc->on_recv(sub{
        my $ch = shift;
        my $msg = shift;
        if( $msg eq 'BUSY' )
    });

}

1;
