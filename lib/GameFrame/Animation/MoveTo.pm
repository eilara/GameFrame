package GameFrame::Animation::MoveTo;

# MoveTo animation - animate a positionable towards another positionable
# even if it is moving with changing velocity, or if my velocity is changing

# TODO add accuracy

use Moose;
use Scalar::Util qw(weaken);
use GameFrame::Util::Vectors;
use aliased 'GameFrame::Animation::CycleLimit';

extends 'GameFrame::Animation::Base';

# target must do compute_destination, xy, xy_vec, speed, and destination_reached
# TODO target is positionable?
has target => (is => 'ro', required => 1, weak_ref => 1,
               handles => [qw(compute_destination xy_vec speed xy
                              destination_reached)]);

sub _build_cycle_limit {
    my $self = shift;
    my $target = $self->target;
    weaken $self;
    weaken $target;
    return sub {
        my ($elapsed, $delta) = @_;

        my $speed   = $target->speed;
        my $to      = $target->compute_destination;
        my $current = $target->xy_vec;
        my $dir_vec = [$to->[0] - $current->[0], $to->[1] - $current->[1]];
        my $dist    = ($dir_vec->[0]**2 + $dir_vec->[1]**2) ** 0.5;

        if ($dist < 1) { # we have arrived
            return $elapsed;
        }

        my $ratio   = $speed * $delta / $dist;
        my $new     = [$current->[0] + $dir_vec->[0]*$ratio, $current->[1] + $dir_vec->[1]*$ratio];

#    my $dir_vec = $to - $current;
#    my $dist    = abs($dir_vec);
#    my $ratio   = $speed * $delta / $dist;
#    my $new     = $current + $dir_vec * $ratio;
#    my $x=$dir_vec*$ratio;

#my $x=$new;print("delta=${\( sprintf('%.3f',$delta))} vec=${\( sprintf('%.3f',$x->[0]))},${\( sprintf('%.3f',$x->[1]))}\n");

        $target->xy($new);

        my $reached = $dist <= 1;
        return $elapsed if $reached;

        # maybe we passed the target
        my $new_dir_vec = [$to->[0] - $new->[0], $to->[1] - $new->[1]];
        my ($x0, $y0, $x1, $y1) = (@$dir_vec, @$new_dir_vec);
        if (
            (
                ($x0 > 0 && $x1 < 0 or $x0 < 0 && $x1 > 0) &&
                ($y0 > 0 && $y1 < 0 or $y0 < 0 && $y1 > 0)
            ) ||
            (
                ($x0 == 0 and $x1 == 0 and $y0*$y1 < 0) ||
                ($y0 == 0 and $y1 == 0 and $x0*$x1 < 0)
            )
        ) {
            my $overshoot = abs(V(@$new) - $to);
            my $real_elapsed = $elapsed - $overshoot/$speed;
            return $real_elapsed;
        }
        return 0;

    };
}

sub cycle_complete {
    my $self = shift;
    $self->xy_vec($self->compute_destination);
    $self->destination_reached;
}

1;

__END__

x y
1 1  1
0 0  0
1 0  0
0 1  0

# TODO problematic when subject is moving wildly and overshoot
#      should switch to "did sign switch on dir vec?"
#        return 1 if $last_dist && ($dist >= $last_dist);
#        $last_dist = $dist;
