package Gearman::Scalable::Spawner;

use strict;
use warnings;

use 5.10.0;

use base 'Gearman::Spawner';
our $VERSION = '0.1';

use Carp qw( croak );
use Gearman::Scalable::Spawner::Supervisor;

sub new {
    my $this = shift;
    my $class = ref $this || $this;

    my %params = @_;

    $params{servers} // croak "need servers";
    $params{workers} // croak "need workers";

    my $pid = Gearman::Scalable::Spawner::Supervisor->start(%params);

    return bless {
        pid => $pid,
    }, $class;
}

1;

__END__
