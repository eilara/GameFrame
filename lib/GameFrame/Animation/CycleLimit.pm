package GameFrame::Animation::CycleLimit;

use Moose;
use Scalar::Util qw(weaken);

# if time is up, return the idealized time or real elapsed if unknown

sub time_period {
    my ($class, $duration) = @_;
    return sub { shift >= $duration? $duration: 0 };
}

sub method_limit {
    my ($class, $method, $target) = @_;
    weaken $target;
    return sub {
        my ($elapsed, $delta) = @_;
        return $target->$method($elapsed, $delta)? $elapsed: 0;
    }
}

1;
