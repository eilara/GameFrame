package GameFrame::Animation::CycleLimit;

use Moose;

sub time_period {
    my ($class, $duration) = @_;
    return sub { shift >= $duration? $duration: 0 };
}

1;
