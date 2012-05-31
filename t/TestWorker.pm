package TestWorker;
use namespace::autoclean;
use lib '../lib';

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);

use Any::Moose;

extends 'Gearman::SlotWorker';

sub BUILD{
    DEBUG 'BUILD ' . __PACKAGE__;
};
sub workmethod{
    my $self = shift;
    my $data = shift;
    DEBUG "workmethod:".$data;
    return "HELLO";
}
sub reverse{
    my $self = shift;
    my $data = shift;
    DEBUG "work:".$data;
    return reverse($data);
}
sub _private{
    my $self = shift;
    my $data = shift;
    DEBUG "_private:".$data;
}
1;
