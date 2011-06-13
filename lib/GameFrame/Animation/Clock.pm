package GameFrame::Animation::Clock;

use Moose;
use EV;
use Coro;

# TODO: time factor for elastic time

sub build_periodic_timer {
    my ($self, $sleep_cb, $tick_cb) = @_;
    return EV::periodic_ns 0, 0, $sleep_cb, $tick_cb;
}

sub now { EV::time() }

1;

