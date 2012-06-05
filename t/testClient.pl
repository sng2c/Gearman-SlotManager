#!/usr/bin/perl
use Gearman::Client;
use JSON;
use Data::Dumper;
use Storable qw(nfreeze thaw);


my $client = Gearman::Client->new();
$client->job_servers('localhost:9955');

my %result;
my $taskset = $client->new_task_set;
for(1..1000){
    print "WORK $1\n";
    $taskset->add_task('TestWorker::reverse', "PING",
    {	
		on_complete => sub{
			my $resstr = ${$_[0]};
			print "ECHO: ";
			print ($resstr);
			print "\n";
		},
                on_fail=>sub{die "FAIL";}
	}
    ); 
}
$taskset->wait;

