package GameFrame::Widget::Panel;

# a box panel 
#
# children must be rectangular event sinks

use Moose;

with qw(
    GameFrame::Role::BackgroundImage
    GameFrame::Role::Event::BoxRouter
);

1;

