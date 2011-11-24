package GameFrame::Role::FollowsWaypoints;

use Moose::Role;
use GameFrame::Util::Vectors;
use aliased 'GameFrame::Grid::Waypoints';

# waypoint followers move along waypoints

has waypoints => (
    is       => 'ro',
    isa      => Waypoints,
    required => 1,
);

has start_time => (is => 'ro');

has animation => (is => 'rw');

has speed => (is => 'ro', reader => 'get_speed', required => 1);

with 'GameFrame::Role::Animated';

around BUILDARGS => sub {
    my ($orig, $class, %args) = @_;
    $args{xy_vec} = V(@{ $args{waypoints}->points_px->[0] });
    return $class->$orig(%args);
};

sub speed {
    my $self = shift;
    return $self->{speed} if @_ == 0;
    my $speed = shift;
    $speed = $speed < 0.01? 0.01: $speed;
    return unless $self->animation;
    $self->{speed} = $speed;
    $self->animation->change_speed($speed);
}

sub follow_waypoints {
    my $self = shift;
    my @wps = @{ $self->waypoints->points_px };
    shift @wps;
    my $t;
    for my $wp (@wps) {
        my $ani = $self->create_animation({
            attribute => 'xy',
            speed     => $self->speed,
            to        => V(@$wp),
        });
        $self->animation($ani);
        $t = $ani->start_animation_and_wait($t || $self->start_time || ());
    }
    return $t;
}

1;


