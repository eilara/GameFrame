package GameFrame::Animation::MoveTo;

# MoveTo animation - animate a positionable towards another positionable
# even if it is moving with changing velocity, or if my velocity is changing

# TODO add accuracy

use Moose;
use aliased 'GameFrame::Animation::CycleLimit';

extends 'GameFrame::Animation::Base';

# target must do compute_destination, xy_vec, and speed
has target => (is => 'ro', required => 1, weak_ref => 1,
               handles => [qw(compute_destination xy_vec speed)]);

has [qw(next_xy last_dist)] => (is => 'rw');

sub _build_cycle_limit {
    my $self = shift;
    return CycleLimit->method_limit(check_move_limit => $self);
}

before start_animation => sub {
    my $self = shift;
    $self->$_(undef) for qw(next_xy last_dist);
};

sub timer_tick {
    my ($self, $elapsed, $delta) = @_;
    $self->xy_vec($self->next_xy) if $delta;
}

sub cycle_complete {
    my $self = shift;
    $self->xy_vec($self->compute_destination);
}

sub check_move_limit {
    my ($self, $elapsed, $delta) = @_;

    my $speed   = $self->speed;
    my $to      = $self->compute_destination;
    my $current = $self->xy_vec;
    my $dir_vec = $to - $current;
    my $dist    = abs($dir_vec);
    my $ratio   = $speed * $delta / $dist;
    my $new     = $current + $dir_vec * $ratio;

#    my $x=$dir_vec*$ratio;
#    print("delta=${\( sprintf('%.3f',$delta))} vec=${\( sprintf('%.3f',$x->[0]))},${\( sprintf('%.3f',$x->[1]))}\n");

    $self->next_xy($new);

    my $reached = $dist <= 1;
    return 1 if $reached;

    my $last_dist = $self->last_dist;
# TODO problematic when subject is moving wildly
    return 1 if $last_dist && ($dist >= $last_dist);
    $self->last_dist($dist);
    return 0;
}

1;


