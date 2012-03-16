package Gearman::Manager::BaseWorker;
use strict;
use Carp qw( croak );
use Data::Dumper;
use Class::Inspector;

use base 'Gearman::Worker';

use fields qw(
jobs
max_jobs
);

sub new {
    my $self = shift;
    $self = fields::new($self) unless ref $self;
    my $slot = shift;
    my $conf = shift;
    $self->{jobs} = 0;
    $self->{max_jobs} = $conf->{max_jobs};
    $self->SUPER::new(job_servers => $conf->{servers});
    my $method_list = Class::Inspector->methods(ref($self), 'expanded');
    my @methods = map{ $_->[2] } grep{ $_->[1] eq ref($self) }@{$method_list};

    foreach my $m (@methods) {
        print ">>>> register method : $m #$slot\n";
        $self->register_method($slot,$m,$conf->{timeout});
    }


    return $self;
}

sub needQuit{
    my $self = shift;
    return $self->{max_jobs}<$self->{jobs};
}

sub register_method {
    my $self = shift;
    my $slot = shift;
    my $method  = shift;
    my $timeout = shift;
    
    croak "$self cannot execute $method" unless $self->can($method);

    $self->{jobs} = 0;
    my $do_work = sub {
	print ">>>> work begin #$slot\n";
        my $job = shift;
        my $paramstr = $job->arg;

        # call the method
        my $retvals = $self->$method($paramstr);

	print ">>>> work done #$slot\n";
        $self->{jobs}++;
        return \$retvals;
    };

    my $func_name = ref($self).'::'.$method;
    if ($timeout) {
        $self->register_function($func_name, $timeout, $do_work);
    }
    else {
        $self->register_function($func_name, $do_work);
    }
    return $func_name;
}




package Gearman::Manager::ProcManager;
use strict;

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
    print ">> ProcMan start #$self->{slot}\n";

    $self->respawn();
}


sub onChildKilled{
    my $self = shift;
    if( $self->{quit} != 1 ){
        print ">> child is killed and respawn #$self->{slot}\n";
        $self->respawn();
    }
    else{
        print ">> child is just killed #$self->{slot}\n";
        undef($self->{cw});
    }
}

sub stop{
    my $self = shift;
    $self->{quit} = 1;
    undef($self->{tw});
    undef($self->{cw});
    kill 'INT', $self->{pid};
    print ">> KILL #$self->{slot} pid:$self->{pid}\n";
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
            print ">> child ends by INT or TERM $self->{slot}\n";
            exit(0); 
        };
        print ">> child starts #$self->{slot}\n";
        $0 = $self->{class}."-worker #".$self->{slot};
        $self->{proc}->();
        print ">> child ends #$self->{slot}\n";
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
    #print "procmanager destruct\n";
}

package Gearman::Manager;

use strict;
use AnyEvent;
use EV;
use AnyEvent::Gearman;
use Carp qw( croak );
use Storable qw( nfreeze thaw );
use Data::Dumper;
use lib qw(. lib );
sub new{
    my $class = shift;
    my $conf = shift;
    my $gconf = delete $conf->{global} or {};
    $gconf->{count} = 1 unless $gconf->{count};
    $gconf->{max_count} = 0 unless $gconf->{max_count};
    $gconf->{max_jobs} = 0 unless $gconf->{max_jobs};
    $gconf->{timeout} = 0 unless $gconf->{timeout};
    $gconf->{servers} = ['localhost'] unless length(@{$gconf->{servers}});
    $gconf->{type} = 'fork' unless $gconf->{type};
    my $body  = {conf=>$conf, gconf=>$gconf, workers=>[]};
    $body->{pid} = $$;
    return bless $body, $class;
}

sub start{
    my $self = shift;
    my @allservers;
    my $parent_pid = $self->{pid};
    my $report_funcname = "report_busy_".$parent_pid;

    #spawn all
    foreach my $class (keys %{$self->{conf}}) {

               # config
        my %conf = %{$self->{gconf}};
        for my $k ( keys %{$self->{conf}->{$class}} ) {
            $conf{$k} = $self->{conf}->{$class}->{$k};
        }


        my $slot = 1;
        foreach my $num (1..$conf{count}) {
            print "$class $slot\n";
            print Dumper(\%conf);

            # add creator
            #my $proc = _fork_proc($class,\%conf,$slot);
            my $proc;
            if($conf{'type'} eq 'exec'){
                $proc = _exec_proc($class,\%conf,$slot);
            }
            else{
                $proc = _fork_proc($class,\%conf,$slot);
            }

            my $procman = Gearman::Manager::ProcManager->new($class,\%conf,$proc,$slot);
            $procman->start();#need to fork
            push(@{$self->{workers}}, $procman);

            push(@allservers,@{$conf{servers}});
            #my $pid = $self->start_worker(servers=>$conf{servers},slot=>$slot,class=>$class);
            #push(@{$self->{workers}}, [$class, $slot, $pid] );
            $slot++;
        }
    }

    {
        use AnyEvent;
        my $condvar = AnyEvent->condvar;
        my $w = AnyEvent->signal(signal=>'INT', cb=>sub{ $condvar->send; });
        
        #report worker
        my %dup;
        map {$dup{$_}=1;} @allservers;
        @allservers = keys(%dup);
        my $report_worker = gearman_worker @allservers;
        print $report_funcname."\n";
        $report_worker->register_function(
            $report_funcname => sub{ 
                my $job = shift;
                my $res = $self->_report_busy($job->workload);
                $job->complete($res);
            },
        );

        ## main loop
        print "running main loop\n";
        $condvar->recv;
        print "ended main loop\n";
        no AnyEvent;
    }

    map{$_->stop(); undef($_);}@{$self->{workers}};
    undef($self->{workers});
}

sub _report_busy{
    my $self = shift;
    my $workload = shift;
    my $data = thaw($workload);
    print "report busy $data\n";
    return nfreeze($data);
}


sub _fork_proc{
    my $class = shift;
    my $conf = shift; 
    my $slot = shift;
    my $creator = sub{
        
        print "start creator $class by ".uc($conf->{type})." #$slot\n";
        my $ok = eval qq{require $class};
        $@ && die $@;
        $ok || die "$class didn't return a true value!";

        
        # create worker and let work
        my Gearman::Manager::BaseWorker $worker = $class->new($slot,$conf);
        my $quitting = 0;
        
        while (!$quitting) {
            eval {
                $worker->work(stop_if => sub {1});
            };
            $@ && warn "$class [$$] failed: $@";
            #$quitting++ if getppid != $supervisor_pid;
            $quitting++ if ($worker->needQuit());
        }
    };
    return $creator;
}


sub _exec_proc{
    use JSON;
    my $class = shift;
    my $conf = shift; 
    my $slot = shift;
    my $confstr = to_json($conf);
    print $confstr."\n";
    my $creator = sub{
        exec "perl", "spawn.pl",$class,$slot,$confstr;    
    };
    no JSON;
    return $creator;
}



sub DESTROY{
    #print "manager destruct\n";
}


1;
