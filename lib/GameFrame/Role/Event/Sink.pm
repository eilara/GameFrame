package GameFrame::Role::Event::Sink;

# these are the methods you can implement if you want to listen to events
# you will only get events if you implement SDLEventHandler, or if you
# place the event sink inside a container which routes events to its children,
# e.g. Widget::Panel

use Moose::Role;

sub on_mouse_motion            {}
sub on_mouse_button_up         {}
sub on_mouse_button_down       {}
sub on_left_mouse_button_up    {}
sub on_left_mouse_button_down  {}
sub on_right_mouse_button_up   {}
sub on_right_mouse_button_down {}
sub on_app_mouse_focus         {}

1;

