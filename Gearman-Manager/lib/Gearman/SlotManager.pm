package Gearman::SlotManager;

# ABSTRACT: Managing Worker's lifecycle with Slots

# VERSION

use namespace::autoclean;
use Any::Moose;

use AnyEvent;
use EV;

has config=>(is=>'rw', isa=>'HashRef');

1;
