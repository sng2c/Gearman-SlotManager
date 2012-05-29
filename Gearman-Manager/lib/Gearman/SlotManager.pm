package Gearman::SlotManager;
use namespace::autoclean;
use Any::Moose;

use AnyEvent;
use EV;

has config=>(is=>'rw', isa=>'HashRef');

1;
