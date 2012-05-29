package Gearman::Manager::ProcManager;
use strict;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);
sub new {
    my $class = shift;
    my $workerclass = shift;
    my $conf = shift;
    my $proc = shift;
    my $slot = shift;
    my $body = {class=>$workerclass,slot=>$slot,conf=>$conf,proc=>$proc,quit=>0};
    return bless $body, $class;
}

sub start{
    my $self = shift;
    DEBUG ">> ProcMan start #$self->{slot}\n";

    $self->respawn();
}


sub onChildKilled{
    my $self = shift;
    if( $self->{quit} != 1 ){
        DEBUG ">> child is killed and respawn #$self->{slot}\n";
        $self->respawn();
    }
    else{
        DEBUG ">> child is just killed #$self->{slot}\n";
        undef($self->{cw});
    }
}

sub stop{
    my $self = shift;
    $self->{quit} = 1;
    undef($self->{tw});
    undef($self->{cw});
    kill 'INT', $self->{pid};
    DEBUG ">> KILL #$self->{slot} pid:$self->{pid}\n";
}

sub fork{
    my $self = shift;

    my $pid = fork;
    if( $pid ){
        return $pid;
    }
    else{
        undef($self->{cw});
        undef($self->{cw});
        $SIG{INT} = $SIG{TERM} = sub {
            DEBUG ">> child ends by INT or TERM $self->{slot}\n";
            exit(0);
        };
        DEBUG ">> child starts #$self->{slot}\n";
        $0 = $self->{class}."-worker #".$self->{slot};
        $self->{proc}->();
        DEBUG ">> child ends #$self->{slot}\n";
        exit(0);
        #exec("perl spawner.pl $self->{class}");
    }
}

sub respawn{
    my $self = shift;
    my $pid = $self->fork();
    $self->{pid} = $pid;
    undef($self->{cw});
    $self->{cw} = AnyEvent->child(pid=>$pid, cb=>sub{$self->onChildKilled(@_);});
}


sub DESTROY{
    my $self = shift;
    DEBUG "procmanager destruct\n";
}


