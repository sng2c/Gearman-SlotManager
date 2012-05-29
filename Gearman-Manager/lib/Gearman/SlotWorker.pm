package Gearman::SlotWorker;
use namespace::autoclean;
use Any::Moose;
use AnyEvent;
use EV;
use Gearman::Worker;
use IPC::AnyEvent::Gearman;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);

has exported=>(is=>'ro',isa=>'ArrayRef[Class::MOP::Method]',
default=>sub{[]});

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
use Data::Dumper;
sub start{
    my $class = shift;
    my $worker = $class->new();
   
    my $cv = AE::cv;

    my $w = Gearman::Worker->new;
    $w->job_servers('localhost:9998');

    foreach my $m (@{$worker->exported}){
        DEBUG "register ".$m->fully_qualified_name;
        my $fname = $m->fully_qualified_name;
        my $fcode = $m->body;
        $w->register_function($fname =>
        sub{
            DEBUG "WORKER ". $fname;
            my $job = shift;
            my $workload = $job->arg;
            my $res = $fcode->($worker,$workload);
            return $res;
        });
    }

    my $t = AE::timer 0, 0.1, sub{
        $w->work(stop_if=>sub{1});
    };

    my $ipcr = IPC::AnyEvent::Gearman->new(servers=>['localhost:9998']);
    $ipcr->listen();
    $cv->recv;
}
1;
