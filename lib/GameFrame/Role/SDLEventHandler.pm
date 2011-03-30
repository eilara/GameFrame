package GameFrame::Role::SDLEventHandler;

use Moose::Role;
use SDL::Events;

# set this before creating any sdl event handlers
my $SDL_Event_Observable;
sub Set_SDL_Event_Observable { $SDL_Event_Observable = shift }

has sdl_event_observable => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
    default  => sub { shift->_build_sdl_event_observable },
);

with 'GameFrame::Role::Event::Sink';

sub _build_sdl_event_observable {
    my $self = shift;
    $SDL_Event_Observable->add_sdl_event_listener($self);
    return $SDL_Event_Observable;
}

sub sdl_event {
    my ($self, $e) = @_;
    if ($e->type == SDL_MOUSEBUTTONUP) {
        $self->on_mouse_button_up($e->motion_x, $e->motion_y);
    } elsif ($e->type == SDL_MOUSEMOTION) {
        $self->on_mouse_motion($e->motion_x, $e->motion_y);
    }
}

# TODO
#    if ($e->type == SDL_APPMOUSEFOCUS) {
#        $cursor->is_visible($e->active_gain);

1;

