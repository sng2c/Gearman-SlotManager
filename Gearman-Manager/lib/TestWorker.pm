package TestWorker;
use namespace::autoclean;
use Any::Moose;
extends 'Gearman::SlotWorker';
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);

sub BUILD{
    DEBUG 'BUILD ' . __PACKAGE__;
};
sub workmethod{
    my $self = shift;
    my $data = shift;
    DEBUG "workmethod:".$data;
    return "HELLO";
}
sub dowork{
    my $self = shift;
    my $data = shift;
    DEBUG "work:".$data;
    return "HELLO";
}

sub _private{
    my $self = shift;
    my $data = shift;
    DEBUG "_private:".$data;
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

