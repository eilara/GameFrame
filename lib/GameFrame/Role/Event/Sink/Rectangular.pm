package GameFrame::Role::Event::Sink::Rectangular;

use Moose::Role;

with 'GameFrame::Role::Event::Sink';

sub on_mouse_enter {}
sub on_mouse_leave {}

1;

