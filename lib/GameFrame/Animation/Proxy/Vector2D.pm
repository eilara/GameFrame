package GameFrame::Animation::Proxy::Vector2D;

use Moose;

extends 'GameFrame::Animation::Proxy';

around set_attribute_value => sub {
    my ($orig, $self, $value) = @_;
    $value->[0] = sprintf('%.0f', $value->[0]);
    $value->[1] = sprintf('%.0f', $value->[1]);
    $self->$orig($value);
};

sub compute_timer_sleep {
    my ($self, $speed) = @_;
    return (cycle_sleep => 1/$speed);
}

1;
