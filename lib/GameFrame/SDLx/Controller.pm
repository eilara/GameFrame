package GameFrame::SDLx::Controller;

use Moose;

use EV;
use Coro::AnyEvent;
use AnyEvent;
use Coro;

use SDL::Event;
use SDL::Events;

# TODO frame paint should be lowest priority?
#      coro signals for events instead of polling?

has [qw(paint_cb event_cb)] => (is => 'rw');

sub run {
    my $self = shift;

    async {
        my $paint_cb    = $self->paint_cb;
        my $event_cb    = $self->event_cb;
        my $update_cb   = GameFrame::Animation::Clock->get_update_cb;
        my $event       = SDL::Event->new;
        my $ideal_tick  = 1/50;
        my $carry = 0;
        while (1) {
            my $tick_begin = EV::time;
            SDL::Events::pump_events();
            $event_cb->($event) while SDL::Events::poll_event($event);
            $update_cb->();
            $paint_cb->();
            my $tick_end = EV::time;
            my $tick_duration = $tick_begin - $tick_end;
            my $expected_duration = $ideal_tick + $carry;
                Coro::AnyEvent::poll;
#           if ($tick_duration <= ($ideal_tick - 0.005)) {
#               my $sleep = $ideal_tick - $tick_duration;
#               Coro::AnyEvent::sleep $sleep;
#               $carry = EV::time - $tick_end - $sleep;
##               print "$carry\n";
#           } else {
#               Coro::AnyEvent::poll;
#           }
        }
    };



#
#    async {
#        my $paint_cb = $self->paint_cb;
#        while (1) {
#           $paint_cb->();
## lower if under load
#           Coro::AnyEvent::sleep 1/60;
#        }
#    };
#
#    async {
#        my $event_cb = $self->event_cb;
#        my $event = SDL::Event->new;
#        while (1) {
#            SDL::Events::pump_events();
#            $event_cb->($event) while SDL::Events::poll_event($event);
## TODO fix
#            Coro::AnyEvent::sleep 1/50;
#        }
#    };

    EV::loop;
}

1;
__END__
    const int TICKS_PER_SECOND = 25;
    const int SKIP_TICKS = 1000 / TICKS_PER_SECOND;
    const int MAX_FRAMESKIP = 5;

    DWORD next_game_tick = GetTickCount();
    int loops;
    float interpolation;

    bool game_is_running = true;
    while( game_is_running ) {

        loops = 0;
        while( GetTickCount() > next_game_tick && loops < MAX_FRAMESKIP) {
            update_game();

            next_game_tick += SKIP_TICKS;
            loops++;
        }

        interpolation = float( GetTickCount() + SKIP_TICKS - next_game_tick )
                        / float( SKIP_TICKS );
        display_game( interpolation );
    }
