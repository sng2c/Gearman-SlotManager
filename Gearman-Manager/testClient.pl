#!/usr/bin/perl
use Gearman::Client;
use JSON;
use Data::Dumper;
use Storable qw(nfreeze thaw);


my $client = Gearman::Client->new();
$client->job_servers('mabook.com:9998');

my %result;
my $taskset = $client->new_task_set;
for(1..5){
$taskset->add_task('TestWorker::echo', "PING",
{	
		on_complete => sub{
			my $resstr = ${$_[0]};
			print "ECHO: ";
			print ($resstr);
			print "\n";
		}
	}
); 
}
$taskset->wait;

