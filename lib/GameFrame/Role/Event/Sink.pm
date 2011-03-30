package GameFrame::Role::Event::Sink;

use Moose::Role;

sub on_mouse_motion {}
sub on_mouse_button_up {}

# TODO
#    if ($e->type == SDL_APPMOUSEFOCUS) {
#        $cursor->is_visible($e->active_gain);

1;

