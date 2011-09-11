package GameFrame::Animation::Curve::Linear;

use Moose;
use Scalar::Util qw(weaken);
use Data::Alias;

extends 'GameFrame::Animation::Curve';

has [qw(from to)] => (is => 'ro', required => 1);

sub _build_from {
    my $self = shift;
    return $self->get_init_value;
}

sub compute_curve_length {
    my $self = shift;
    my $delta = $self->to - $self->from;
    return abs($delta);
}

sub solve_edge_value {
    my ($self, $elapsed) = @_;
    my $final = $elapsed? 'to': 'from';
    return $self->$final;
}

sub _build_solve_curve_cb {
    my $self = shift;
    weaken $self;
    alias my $from = $self->{from};
    alias my $to   = $self->{to};
    return sub { $from + shift() * ($to - $from) };
}

1;

__END__

