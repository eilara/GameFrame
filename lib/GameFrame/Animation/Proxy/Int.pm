package GameFrame::Animation::Proxy::Int;

use Moose;

extends 'GameFrame::Animation::Proxy';

around set_attribute_value => sub {
    my ($orig, $self, $value) = @_;
    my $round = sprintf('%.0f', $value);
    $self->$orig($round);
};

1;
