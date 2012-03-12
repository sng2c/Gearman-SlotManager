package Gearman::Scalable::Spawner::Supervisor;

use strict;
use warnings;
use base 'Gearman::Spawner::Supervisor';
use Gearman::Spawner::Process;
use Gearman::Worker; ###

sub process { Gearman::Spawner::Process->instance }

# forks a child process to run the manager in, then brings up requested workers
# returns the pid of the forked supervisor the "workers" parameter is a hash of
# worker class names to their respective startup arguments
sub start {
    my $class = shift;

    my $supervisor = $class->new(@_); # new takes the same parameters as start

    # try loading modules before fork so obvious compile errors get reported to
    # caller
    $supervisor->try_load_modules;

    my $pid = process->fork("[Gearman::Scalable::Spawner] $0", 1);
    return $pid if $pid;

    $supervisor->spawn;
    
    process->loop;

    die "manager exited unexpectedly";
}

sub new {
    my $class = shift;
    return bless {
        # allowed parameters: servers, workers, preload
        @_,
        _pid => $$,
    }, $class;
}

# launch workers in subprocesses
sub spawn {
    my $self = shift;

    $self->load_modules;
    
    $self->register_watcher; ###

    my $workers = $self->{workers};
    for my $class (keys %$workers) {
        my $config = $workers->{$class};

        my $count = delete $config->{count} || 1; # worker count
        my $maxcount = delete $config->{max_count} || 1; ### worker + part-timer count

        for my $n (1 .. $count) {
            my $slot = $n;

            my $handle = process->maintain_subprocess(sub {
                $self->start_worker(
                    servers => $self->{servers},
                    class   => $class,
                    slot    => $slot,
                    %$config,
                );
            });
            $self->{_handles}{"$class #$n"} = $handle;
        }
    }

    return $self;
}

###
=pod
sub register_watcher{
    my $self = shift;
    my $supervisor_pid = $$;
    my $servers = $self->{servers};
    my $worker = Gearman::Worker->new;
    $worker->job_servers($servers);
    $worker->register_function('report_begin' => sub{});
    $worker->register_function('report_done' => sub{});
    $worker->work while 1;
}
=cut

# fork a worker process and start grabbing jobs
sub start_worker {
    my $self = shift;
    my %params = @_;

    my $supervisor_pid = $$;

    my $pid = process->fork("$params{class}-worker #$params{slot}"); ##
    return $pid if $pid;

    print "worker born #$pid\n";
    my $worker = $params{class}->new(
        $params{servers}, $params{slot}, $params{data}
    );

    my $quitting = 0;
    my $jobs_done = 0;
    $SIG{INT} = $SIG{TERM} = sub { $quitting = 1 };
    while (!$quitting) {
        eval {
            $worker->work(stop_if => sub {1});
        };

        $@ && warn "$params{class} [$$] failed: $@";
        $jobs_done++;

        # bail if supervisor went away
        $quitting++ if getppid != $supervisor_pid;
        $quitting++ if $params{max_jobs} && $jobs_done > $params{max_jobs};
    }
    exit 0;
}

1;
