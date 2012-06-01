package Manager;
use Moose;
with 'MooseX::Role::Pluggable';

no Moose;

package main;

my $man = Manager->new(
    {plugins=>[qw(+Worker::Test +Worker::Test2)]}
);
foreach my $p ( @{$man->plugin_list} )
{
    print '['.$p->name."]\n";
    if( $p->can('work') ){
        $p->work();
    }
}
