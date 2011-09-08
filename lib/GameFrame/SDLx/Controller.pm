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

my $FPS = 62;

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
#print "expected-actual=${\( sprintf('%.4f',$left_in_tick) )}\n";            
#my $x1=EV::time;
#print "sleep was=${\( sprintf('%.4f',EV::time - $x1) )}   carry=$carry\n";
#            my $tick_end = EV::time;
#            my $actual_tick_duration = $tick_end - $tick_begin;
#            my $expected_tick_duration = $ideal_tick - $carry;
#            my $left_in_tick = $expected_tick_duration - $actual_tick_duration;
#            SDL::delay(1000*$left_in_tick) if $left_in_tick > 0;
#            $carry = EV::time - $tick_begin - $ideal_tick;
        my $ideal_tick  = 1/62;
        my $carry       = 0;
