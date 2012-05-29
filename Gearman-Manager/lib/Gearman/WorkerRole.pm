package Gearman::WorkerRole;
use namespace::autoclean;
use Moose::Role;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);

has exported=>(is=>'ro',isa=>'ArrayRef[Class::MOP::Method]',
default=>sub{[]});

after 'BUILD'=>sub{
    my $self = shift;
    DEBUG ref($self);
    my $meta = $self->meta();
    my $package = $meta->{package};
    my $exported = $self->exported();

    for my $method ( $meta->get_all_methods) 
    {
        my $packname = $method->package_name;
        my $methname = $method->name;
        if( $packname eq $package )
        {
            if( $methname !~ /^_/ && $methname ne uc($methname) && $methname ne 'meta' )
            {
                if( !$meta->has_attribute($methname) ){
                    DEBUG 'filtered: '.$method->fully_qualified_name;
                    push(@{$exported},$method);
                }
            }
        }
    }
};



sub BUILD{
};

1;
