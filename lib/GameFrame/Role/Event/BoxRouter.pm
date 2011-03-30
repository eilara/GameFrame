package GameFrame::Role::Event::BoxRouter;

use Moose::Role;

with qw(
    GameFrame::Role::Event::Sink
    GameFrame::Role::Panel::Box
);

# child events handled before parent events

before on_mouse_motion => sub {
    my ($self, @mouse_xy) = @_;
    $self->_find_child_at(@mouse_xy)->on_mouse_motion(@mouse_xy);
};

before on_mouse_button_up => sub {
    my ($self, @mouse_xy) = @_;
    $self->_find_child_at(@mouse_xy)->on_mouse_button_up(@mouse_xy);
};

1;

