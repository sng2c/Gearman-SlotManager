# NAME

AnyEvent::Gearman::WorkerPool - Managing Worker's lifecycle with Slots

# VERSION

version 0.4

# SYNOPSIS

worker\_pool.pl

        #!/usr/bin/env perl

        use AnyEvent;
        use AnyEvent::Gearman::WorkerPool;
        
        my $cv = AE::cv;

        my $sig = AE::signal 'INT'=> sub{ 
                DEBUG "TERM!!";
                $cv->send;
        };

        my $pool = AnyEvent::Gearman::WorkerPool->new(
                config=>
                {   
                        global=>{ # common config
                                job_servers=>['localhost'], # gearmand servers
                                libs=>['./lib'], # perl5 library paths
                                max=>3, # max workers
                                },  
                        slots=>{
                                'TestWorker'=>{ # module package name which extends AnyEvent::Gearman::WorkerPool::Worker.
                                        min=>20, # min workers, count when started.
                                        max=>50, # overrides global config's max. Workers will extend when all workers are busy.
                                        workleft=>10, # workleft is life of worker. A worker will be respawned after used 10 times. 
                                                                # if workleft is set as 0, a worker will be never respawned.
                                                                # this feature is useful if worker code may has some memory leaks.
                                },
                                # you can place more worker modules here.
                        }   
                }   
        );

        $pool->start();

        my $res = $cv->recv;
        undef($tt);
        $pool->stop;
        undef($pool);

lib/TestWorker.pm

        package TestWorker;
        use Log::Log4perl qw(:easy);
        Log::Log4perl->easy_init($DEBUG);

        use Moose;

        extends 'AnyEvent::Gearman::WorkerPool::Worker';

        sub slowreverse{ # exported
                my $self = shift;
                my $data = shift;
                sleep(1);
                return reverse($data);
        }
        sub reverse{ # exported
                my $self = shift;
                my $data = shift;

                return reverse($data);
        }
        sub _private{ # private
                my $self = shift;
                my $data = shift;
                DEBUG "_private:".$data;
        }

        1;

client.pl

        #!/usr/bin/env perl
        use AnyEvent;
        use AnyEvent::Gearman;
        my $cv = AE::cv;
        my $c = gearman_client 'localhost';
        $c->add_task(
                'TestWorker::reverse' => 'HELLO WORLD', # 'MODULE_NAME::EXPORTED_METHOD' => PAYLOAD
                on_complete=>sub{
                        my $reversed = $_[1];
                        $cv->send( $reversed );
                },
        );

        my $reversed = $cv->recv;

        print $reversed."\n"; # 'DLROW OLLEH'

# AUTHOR

HyeonSeung Kim <sng2nara@hanmail.net>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by HyeonSeung Kim.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
