package GameFrame::Animation::Clock;

use Moose;
use Set::Object;
use EV;

my $Timer;
my $Callbacks = Set::Object->new;

# used by controller
sub get_update_cb {
    return sub {
        my $t = EV::time;
        $_->($t) for $Callbacks->members;
    };
}

sub build_periodic_timer {
    my ($self, $start_time, $timer_sleep, $tick_cb) = @_;
    return GameFrame::Animation::Clock::Timer->new
        (cbs => $Callbacks, cb => $tick_cb);
}

sub now { EV::time }

package GameFrame::Animation::Clock::Timer;

use Moose;

has cb  => (is => 'ro');
has cbs => (is => 'ro');

sub start  {
    my $self = shift;
    $self->cbs->insert($self->cb);        
}

sub stop {
    my $self = shift;
    $self->cbs->remove($self->cb);        
}

sub is_active {
    my $self = shift;
    return $self->cbs->contains($self->cb);
}

1;

