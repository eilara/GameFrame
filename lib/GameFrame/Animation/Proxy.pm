package GameFrame::Animation::Proxy;

use Moose;
use MooseX::Types::Moose qw(Bool Str);

has target    => (is => 'ro', required => 1, weak_ref => 1);
has attribute => (is => 'ro', isa => Str, required => 1);

sub get_init_value {
    my $self = shift;
    my $att = $self->attribute;
    return $self->target->$att;
}

sub set_attribute_value {
    my ($self, $value) = @_;
    my $att = $self->attribute;
    $self->target->$att($value);
}

# default proxy has nothing to say about preferred cycle sleep between ticks
sub compute_timer_sleep {
    my ($self, $speed) = @_;
    return ();
}

1;
