package Gearman::SlotManager;
# ABSTRACT: Managing Worker's lifecycle with Slots
# VERSION
use Devel::GlobalDestruction;
use namespace::autoclean;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);
use Data::Dumper;
use Any::Moose;

use AnyEvent;
use EV;

use Gearman::Slot;
has slotmap=>(is=>'rw', isa=>'HashRef', default=>sub{ return {}; });
has confmap=>(is=>'rw', isa=>'HashRef', default=>sub{ return {}; });
has config=>(is=>'rw', isa=>'HashRef',required=>1);

sub BUILD{
    my $self = shift;

    my $conf = $self->config;
    my %global = %{$conf->{'global'}};
    my %baseconf = (
        job_servers=>[''],
        min=>1,
        max=>1,
        workleft=>0,
    );
    %global = (%baseconf,%global);
    
    my %confs = %{$conf->{slots}};
    foreach my $worker (keys %confs){
        my %conf = %{$confs{$worker}};

        %conf = (%global,%conf);
        #DEBUG Dumper(\%conf);

        my @slots;
        foreach (1 .. $conf{max}){
            my $slot = Gearman::Slot->new(
                job_servers=>$conf{job_servers},
                libs=>$conf{libs},
                workleft=>$conf{workleft},
                worker_package=>$worker,
                worker_channel=>$worker.'#'.$_,
            );
            push( @slots, $slot);
        }
        $self->slotmap->{$worker} = \@slots;
        $self->confmap->{$worker} = \%conf;
    }
}

sub DEMOLISH{
    return if in_global_destruction;
    DEBUG __PACKAGE__.' DEMOLISHED';
}

__PACKAGE__->meta->make_immutable;
1;
