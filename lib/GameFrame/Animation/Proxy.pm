package GameFrame::Animation::Proxy;

use Moose;
use MooseX::Types::Moose qw(Str);

has target    => (is => 'ro', required => 1, weak_ref => 1);
has attribute => (is => 'ro', isa => Str, required => 1);

sub set_attribute_value {
    my ($self, $value) = @_;
    my $att = $self->attribute;
    $self->target->$att($value);
}

1;
