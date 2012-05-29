package TestWorker;
use namespace::autoclean;
use Moose;
extends 'Gearman::SlotWorker';
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);

sub BUILD{
    DEBUG 'BUILD ' . __PACKAGE__;
};
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

=pod
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


TestWorker->run();
=cut

