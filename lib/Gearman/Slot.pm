package Gearman::Slot;

use Devel::GlobalDestruction;
# ABSTRACT: Slot class
# VERSION
use namespace::autoclean;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);

use Any::Moose;
use AnyEvent;
use Gearman::SlotWorker;
use IPC::AnyEvent::Gearman;
use Scalar::Util qw(weaken);
use UUID::Random;

has libs=>(is=>'rw',isa=>'ArrayRef',default=>sub{[]});
has job_servers=>(is=>'rw',isa=>'ArrayRef',required=>1);
has workleft=>(is=>'rw');
has worker_package=>(is=>'rw');
has worker_channel=>(is=>'rw');

has ipc=>(is=>'rw');
has is_busy=>(is=>'rw');
has is_stopped=>(is=>'rw');

has worker_watcher=>(is=>'rw');
has worker_pid=>(is=>'rw');

sub BUILD{
    my $self = shift;
    $self->ipc( IPC::AnyEvent::Gearman->new(job_servers=>$self->job_servers));
    $self->ipc->listen;
    $self->ipc->on_recv(sub{
        my $ch = shift;
        my $msg = shift;
        if( $msg eq 'BUSY' ){
            $self->is_busy(1);  
        }
        elsif( $msg eq 'NOTBUSY' ){
            $self->is_busy(1);  
        }
        elsif( $msg eq 'STOP' ){
            $self->kill();
        }
    });

    weaken($self);
}

sub stop{
    my $self = shift;
    $self->is_stopped(1);
    $self->ipc->send($self->worker_channel,'STOP');
}

sub spawn{
    my $self = shift;
    $self->is_stopped(0);

    my $cpid = fork();
    if( $cpid ){
        $self->worker_pid($cpid);
        $self->worker_watcher( AE::child $cpid, sub{
            my ($pid,$status) = @_;
            if( $self->is_stopped != 1){
                DEBUG 'child respawn OK';
                $self->spawn();
            }
            else{
                DEBUG 'kill child OK';
                $self->worker_pid(undef);
                $self->worker_watcher(undef);
            }
        });
        weaken($self);
    }
    else{
        my $class = $self->worker_package;
        my $worker_channel = $self->worker_channel;
        my $libs = join(' ',map{"-I$_"}@{$self->libs});;
        my $workleft = $self->workleft;

        my $parent_channel = $self->ipc->channel;
        my $job_servers = '['.join(',',map{"\"$_\""}@{$self->job_servers}).']';

        my $cmd = qq!perl $libs -M$class -e '$class -> Loop(job_servers=>$job_servers,parent_channel=>"$parent_channel",channel=>"$worker_channel",workleft=>$workleft);' !;
        
        DEBUG 'spawn '.$cmd;
        my $res = 0;
        $res = exec($cmd);
        die "unexpected error $res";
    }
}

sub DEMOLISH{
    return if in_global_destruction;

    DEBUG __PACKAGE__.' DEMOLISHED';
    my $self = shift;
    if( $self->worker_pid ){
        DEBUG 'killed child forcely';
        kill 9, $self->worker_pid;
    }
}

__PACKAGE__->meta->make_immutable;
1;
