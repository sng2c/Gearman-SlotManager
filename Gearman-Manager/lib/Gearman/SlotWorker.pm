package Gearman::SlotWorker;
use namespace::autoclean;
use Moose;
use AnyEvent;
use EV;
use AnyEvent::Gearman;
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

sub start{
    my $class = shift;
    my $worker = $class->new();
    my $cv = AE::cv;

    my $w = gearman_worker 'localhost:9999';
    foreach my $m (@{$worker->exported}){
        DEBUG "register ".$m->fully_qualified_name;
        $w->register_function($m->fully_qualified_name=>
        sub{my $job=shift;
            return $m->execute($worker,$job);
        });
    }

    my $ipcr = IPC::AnyEvent::Gearman->new(servers=>['localhost:9999']);
    $ipcr->listen();

    $cv->recv;
}
1;
