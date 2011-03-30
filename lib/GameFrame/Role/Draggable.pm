package GameFrame::Role::Draggable;

use Moose::Role;

with qw(
    GameFrame::Role::SDLEventHandler
    GameFrame::Role::Positionable
);

sub on_mouse_motion {
    my ($self, $x, $y) = @_;
    $self->x($x);
    $self->y($y);
}

1;


