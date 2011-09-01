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

has speed => (is => 'ro');

with 'GameFrame::Role::Animated';
#with 'GameFrame::Role::Movable';

around BUILDARGS => sub {
    my ($orig, $class, %args) = @_;
    $args{xy_vec} = V(@{ $args{waypoints}->points_px->[0] });
    return $class->$orig(%args);
};

sub follow_waypoints {
    my $self = shift;
    my @wps = @{ $self->waypoints->points_px };
    shift @wps;
    my $t;
    for my $wp (@wps) {
        my $ani = $self->create_animation({
            attribute => 'xy_vec',
            speed     => $self->speed,
            to        => V(@$wp),
        });
        $t = $ani->start_animation_and_wait($t || $self->start_time || ());
    }
}

1;


