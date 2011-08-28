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

with 'GameFrame::Role::Movable';

around BUILDARGS => sub {
    my ($orig, $class, %args) = @_;
    $args{xy_vec} = V(@{ $args{waypoints}->points_px->[0] });
    return $class->$orig(%args);
};

sub follow_waypoints {
    my $self = shift;
    my @wps = @{ $self->waypoints->points_px };
    $self->xy(shift @wps);
    $self->move_to(V(@{ shift @wps }));
    for my $wp (@wps) {
      $self->restart_move_to(V(@$wp));
    }
}

1;


