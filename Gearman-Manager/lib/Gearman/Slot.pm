package Gearman::SlotManager;

use Any::Moose;

use AnyEvent;
use EV;

has config=>(is=>'rw', isa=>'HashRef');
has slots=>(is=>'rw', isa=>'ArrayRef[]', default=>sub{return [];});

sub start{
}

sub stop{
}

1;
