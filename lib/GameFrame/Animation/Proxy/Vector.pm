package GameFrame::Animation::Proxy::Vector;

# TODO this is actually a 2D int vector

use Moose;

extends 'GameFrame::Animation::Proxy';

around set_attribute_value => sub {
    my ($orig, $self, $value) = @_;
    $self->$orig([map { sprintf('%.0f', $_) } @$value]);
};

sub compute_timer_sleep {
    my ($self, $speed) = @_;
    return (cycle_sleep => 1/$speed);
}

1;
