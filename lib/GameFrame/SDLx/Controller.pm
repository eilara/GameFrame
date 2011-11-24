package GameFrame::SDLx::Controller;

use Moose;

use EV;
use Coro::AnyEvent;
use AnyEvent;
use Coro;

use SDL;
use SDLx::FPS;
use SDL::Event;
use SDL::Events;

use GameFrame::Animation::Clock;

my $FPS = 52;

has [qw(paint_cb event_cb)] => (is => 'rw');

sub run {
    my $self = shift;
    my $fps = SDLx::FPS->new(fps => $FPS);
    my $is_slow;
    async {
        my $paint_cb   = $self->paint_cb;
        my $event_cb   = $self->event_cb;
        my $update_cb  = GameFrame::Animation::Clock->get_update_cb;
        my $event      = SDL::Event->new;
        my $tick_start = EV::time;
        my $is_slow;
        while (1) {
            SDL::Events::pump_events();
            $event_cb->($event) while SDL::Events::poll_event($event);
            $update_cb->();
            $paint_cb->() unless $is_slow;
            Coro::AnyEvent::poll;
            $fps->delay;

            my $tick_end = EV::time;
            if ($is_slow) {
                $is_slow = 0;
            } elsif ((1/($tick_end - $tick_start) + 15) < $FPS) {
                $is_slow = 1;
            }
            $tick_start = $tick_end;
        }
    };

    EV::loop;
}

1;

__END__
