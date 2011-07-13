package GameFrame::Animation::MoveTo;

# MoveTo animation - animate a positionable towards another positionable
# even if it is moving with changing velocity, or if my velocity is changing

use Moose;
use Scalar::Util qw(weaken);
use GameFrame::MooseX;
use aliased 'GameFrame::Animation::Timeline';
use aliased 'GameFrame::Animation::CycleLimit';

# target must do compute_destination, xy_vec, and speed
has target => (is => 'ro', required => 1, weak_ref => 1,
               handles => [qw(compute_destination xy_vec speed)]);

has [qw(next_xy last_dist)] => (is => 'rw');

compose_from Timeline,
    inject => sub {
        my $self = shift;
        weaken $self;
        my $cycle_limit = CycleLimit->method_limit(check_move_limit => $self);
        return (
            cycle_limit => $cycle_limit,
            provider    => $self,
        );
    },        
    has => {handles => {
        _start_animation            => 'start',
        restart_animation           => 'restart',
        stop_animation              => 'stop',
        pause_animation             => 'pause',
        resume_animation            => 'resume',
        is_animation_started        => 'is_timer_active',
        wait_for_animation_complete => 'wait_for_animation_complete',
    }};

with 'GameFrame::Role::Animation';

sub start_animation {
    my $self = shift;
    $self->$_(undef) for qw(next_xy last_dist);
    $self->_start_animation;
}

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


