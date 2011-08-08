package GameFrame::SDLx::Controller;

use Moose;

use EV;
use Coro::AnyEvent;
use AnyEvent;
use Coro;

use SDL::Event;
use SDL::Events;

has [qw(paint_cb event_cb)] => (is => 'rw');

sub run {
    my $self = shift;

    async {
        my $paint_cb = $self->paint_cb;
        while (1) {
            $paint_cb->();
            Coro::AnyEvent::sleep 1/50;
        }
    };

    async {
        my $event_cb = $self->event_cb;
        my $event = SDL::Event->new;
        while (1) {
            SDL::Events::pump_events();
            $event_cb->($event) while SDL::Events::poll_event($event);
            Coro::AnyEvent::sleep 1/50;
        }
    };

    EV::loop;
}

1;
