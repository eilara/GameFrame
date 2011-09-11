package GameFrame::Animation::Proxy;

use Moose;
use MooseX::Types::Moose qw(Bool Str);
use Scalar::Util qw(weaken);
use Data::Alias;

has target    => (is => 'ro', required => 1, weak_ref => 1);
has attribute => (is => 'ro', isa => Str, required => 1);

sub get_init_value {
    my $self = shift;
    my $att = $self->attribute;
    return $self->target->$att;
}

sub build_set_value_cb {
    my $self = shift;
    weaken $self;
    alias my $att    = $self->attribute;
    alias my $target = $self->target;
    return sub {
        my $value = shift;
        $target->$att($value);
    };
}

1;
