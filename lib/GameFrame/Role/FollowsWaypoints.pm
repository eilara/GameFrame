package GameFrame::Role::FollowsWaypoints;

use Moose::Role;
use Coro;
use Math::Vector::Real;
use aliased 'GameFrame::Grid::Waypoints';

# waypoint followers move along waypoints

has waypoints => (
    is       => 'ro',
    isa      => Waypoints,
    required => 1,
);

with 'GameFrame::Role::Movable';

sub follow_waypoints {
    my $self = shift;
    my @wps = @{ $self->waypoints->points_px };
    $self->xy(shift @wps);
    for my $wp (@wps) {
        $self->move_to($wp);
    }
}

1;


