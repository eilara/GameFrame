package GameFrame::Animation::Proxy::Vector;

# TODO this is actually a 2D int vector

use Moose;

extends 'GameFrame::Animation::Proxy';

around set_attribute_value => sub {
    my ($orig, $self, $value) = @_;
    $self->$orig([map { sprintf('%.0f', $_) } @$value]);
};

1;
