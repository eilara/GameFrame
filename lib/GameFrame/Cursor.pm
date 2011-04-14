package GameFrame::Cursor;

use Moose;

with qw(
    GameFrame::Role::AnimatedSprite
    GameFrame::Role::Draggable
);

# hide/show this cursor when entering/leaving app
sub on_app_mouse_focus { shift->is_visible(pop) }

1;
