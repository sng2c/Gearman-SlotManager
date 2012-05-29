use strict;
use Carp qw( croak );
use Data::Dumper;
use Class::Inspector;
use Gearman::Client;
use Storable qw( nfreeze thaw);
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);
use base 'Gearman::Worker';

use fields qw(
jobs
conf
client
);

sub new {
    my $self = shift;
    $self = fields::new($self) unless ref $self;
    my $slot = shift;
    my $conf = shift;

    $self->{jobs} = 0;
    $self->{conf} = $conf;
    $self->SUPER::new(job_servers => $conf->{servers});
    my $method_list = Class::Inspector->methods(ref($self), 'expanded');
    my @methods = map{ $_->[2] } grep{ $_->[1] eq ref($self) && $_->[2] =~ /^work_/ }@{$method_list};

    foreach my $m (@methods) {
        DEBUG ">>>> register method : $m #$slot\n";
        $self->register_method($slot,$m,$conf->{timeout});
    }

    $self->{client} = Gearman::Client->new();
    $self->{client}->job_servers($self->{conf}->{servers});

    return $self;
}

sub needQuit{
    my $self = shift;
    return $self->{conf}->{max_jobs}<$self->{jobs};
}

sub report_busy{
    my $self = shift;
    my $busy = shift;
#    DEBUG ">>>> report busy $busy\n";
    $self->{client}->dispatch_background(
            $self->{conf}->{report_funcname},
            nfreeze({busy=>$busy,slot=>$self->{conf}->{slot},class=>$self->{conf}->{class}}));
}

sub register_method {
    my $self = shift;
    my $slot = shift;
    my $method  = shift;
    my $timeout = shift;
    $method =~ /^work_(.+)/;
    my $method_export = $1;
    croak "$self cannot execute $method" unless $self->can($method);

    $self->{jobs} = 0;
    my $do_work = sub {
#      DEBUG ">>>> work begin #$slot\n";
        $self->report_busy(1);
        my $job = shift;
        my $paramstr = $job->arg;

        # call the method
        my $retvals = $self->$method($paramstr);

#      DEBUG ">>>> work done #$slot\n";
        $self->report_busy(0);
        $self->{jobs}++;
        return \$retvals;
    };

    my $func_name = ref($self).'::'.$method_export;
    if ($timeout) {
        $self->register_function($func_name, $timeout, $do_work);
    }
    else {
        $self->register_function($func_name, $do_work);
    }
    return $func_name;
}
ackage Gearman::Manager::BaseWorker;
use strict;
use Carp qw( croak );
use Data::Dumper;
use Class::Inspector;
use Gearman::Client;
use Storable qw( nfreeze thaw);
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);
use base 'Gearman::Worker';

use fields qw(
jobs
conf
client
);

sub new {
    my $self = shift;
    $self = fields::new($self) unless ref $self;
    my $slot = shift;
    my $conf = shift;
     
    $self->{jobs} = 0;
    $self->{conf} = $conf;
    $self->SUPER::new(job_servers => $conf->{servers});
    my $method_list = Class::Inspector->methods(ref($self), 'expanded');
    my @methods = map{ $_->[2] } grep{ $_->[1] eq ref($self) && $_->[2] =~ /^work_/ }@{$method_list};

    foreach my $m (@methods) {
        DEBUG ">>>> register method : $m #$slot\n";
        $self->register_method($slot,$m,$conf->{timeout});
    }

    $self->{client} = Gearman::Client->new();
    $self->{client}->job_servers($self->{conf}->{servers});

    return $self;
}

sub needQuit{
    my $self = shift;
    return $self->{conf}->{max_jobs}<$self->{jobs};
}

sub report_busy{
    my $self = shift;
    my $busy = shift;
#    DEBUG ">>>> report busy $busy\n";
    $self->{client}->dispatch_background(self->{client}->dispatch_background(

