package TestWorker;
use namespace::autoclean;
use Moose;
with 'Gearman::WorkerRole';
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);

sub workmethod{
    my $self = shift;
    DEBUG "workmethod:".$self;
}
sub dowork{
    my $self = shift;
    DEBUG "work:".$self;
}

sub _private{
    my $self = shift;
    DEBUG "_private:".$self;
}

package main;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);
my $t = TestWorker->new();
use Data::Dumper;


my @mt = @{$t->exported};


foreach my $m (@mt){
    DEBUG $m->name;
    #$m->body->();
    $m->execute($t);
}





