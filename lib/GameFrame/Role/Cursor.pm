package GameFrame::Role::Cursor;

use Moose::Role;

with qw(
    GameFrame::Role::Paintable
    GameFrame::Role::Draggable
);

# hide/show this cursor when entering/leaving app
sub on_app_mouse_focus { shift->is_visible(pop) }

1;
