package GameFrame::Role::Movable;

use Moose::Role;
use MooseX::Types::Moose qw(Num);
use aliased 'GameFrame::Animation::Timeline';
use aliased 'GameFrame::Animation::CycleLimit';
use Math::Vector::Real;

# speed in pixels per second
has speed => (is => 'rw', isa => Num, required => 1);

has to        => (is => 'rw');
has next_xy   => (is => 'rw');
has last_dist => (is => 'rw', default => 2**16);

with 'GameFrame::Role::Positionable';

# move with variable velocity towards a changing target
sub move_to {
    my ($self, $to) = @_;

    my $to_code = ref($to) eq 'CODE'? $to: sub { $to };
    $self->to($to_code);

    my $cycle_limit = CycleLimit->method_limit(check_move_limit => $self);
    my $timeline = Timeline->new(
        cycle_limit => $cycle_limit,
        provider    => $self,
    );
    $timeline->start;
    $timeline->wait_for_animation_complete;
}

sub timer_tick {
    my ($self, $elapsed, $delta) = @_;
    $self->xy_vec($self->next_xy) if $delta;
}

sub cycle_complete {
    my $self = shift;
    $self->xy_vec($self->to->());
    $self->last_dist(2**16); # should also reset on stop
}

sub check_move_limit {
    my ($self, $elapsed, $delta) = @_;

    my $speed   = $self->speed;
    my $to      = $self->to->();
    my $current = $self->xy_vec;
    my $dir_vec = $to - $current;
    my $dist    = abs($dir_vec);
    my $ratio   = $speed * $delta / $dist;
    my $new     = $current + $dir_vec * $ratio;

    $self->next_xy($new);

    my $reached = $dist <= 1;
    return 1 if $reached;

    my $last_dist = $self->last_dist;
# TODO problematic when subject is moving wildly
    return 1 if $dist >= $last_dist;
    $self->last_dist($dist);
    return 0;
}

# returns by how many pixels per second did we slow
sub slow {
    my ($self, $percent) = @_;
    my $speed = $self->speed;
    my $delta_speed = $speed * ($percent/100);
    $self->speed($speed - $delta_speed);
    return $delta_speed;
}

sub haste {
    my ($self, $delta_speed) = @_;
    $self->speed($self->speed + $delta_speed);
}

1;


