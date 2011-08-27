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

has last_dist => (is => 'rw');

sub _build_cycle_limit {
    my $self = shift;
    my $target = $self->target;
    weaken $self;
    weaken $target;
    my $last_dist;
    $self->last_dist(\$last_dist);
    return sub {
        my ($elapsed, $delta) = @_;

        my $speed   = $target->speed;
        my $to      = $target->compute_destination;
        my $current = $target->xy_vec;
        my $dir_vec = [$to->[0] - $current->[0], $to->[1] - $current->[1]];
        my $dist    = ($dir_vec->[0]**2 + $dir_vec->[1]**2) ** 0.5;

        if ($dist < 1) { # we have arrived
            return 1;
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
        return 1 if $reached;

    # maybe we passed the target

# TODO problematic when subject is moving wildly and overshoot
#      should switch to "did sign switch on dir vec?"
        return 1 if $last_dist && ($dist >= $last_dist);
        $last_dist = $dist;
        return 0;
    };
}

before start_animation => sub {
    my $self = shift;
    my $last_dist = $self->last_dist;
    $$last_dist = undef if $last_dist;
};

sub timer_tick {}

sub cycle_complete {
    my $self = shift;
    $self->xy_vec($self->compute_destination);
    $self->destination_reached;
}

1;

__END__



