package GameFrame::Window;

# a top level window 
#
# children must be rectangular event sinks, e.g. BoxRouter

use Moose;

with qw(
    GameFrame::Role::SDLEventHandler
    GameFrame::Role::Event::BoxRouter
);

1;

