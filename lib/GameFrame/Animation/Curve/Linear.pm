package GameFrame::Animation::Curve::Linear;

use Moose;

has [qw(from to)] => (is => 'ro', required => 1);

sub _build_from {
    my $self = shift;
    return $self->get_init_value;
}

sub curve_length {
    my $self = shift;
    my $delta = $self->to - $self->from;
    return abs($delta);
}

sub solve_edge_value {
    my ($self, $elapsed) = @_;
    my $final = $elapsed? 'to': 'from';
    return $self->$final;
}

sub solve_curve {
    my ($self, $elapsed) = @_;
    my $from  = $self->from;
    my $delta = $self->to - $from;
    my $value = $from + $elapsed * $delta;
    return $value;
}

1;

__END__

