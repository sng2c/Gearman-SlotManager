package Worker::Test;
use Moose;
with 'MooseX::Role::Pluggable::Plugin';

sub work {
  my( $self ) = shift;
 
  print __PACKAGE__."!!!\n";
  # yadda yadda yadda
}
 
