package GameFrame::Animation::Clock;

use Moose;
use EV;

sub build_periodic_timer {
    my ($self, $start_time, $timer_sleep, $tick_cb) = @_;
    return EV::periodic_ns $start_time, $timer_sleep, 0, $tick_cb;
}

sub now { EV::time }

1;

