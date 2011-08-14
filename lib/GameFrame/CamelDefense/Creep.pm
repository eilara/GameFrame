package GameFrame::CamelDefense::Creep;

use Moose;

with qw(
    GameFrame::Role::FollowsWaypoints
    GameFrame::Role::AnimatedSprite
    GameFrame::Role::HealthBar
    GameFrame::Role::Active::Child
);

sub start {
    my $self = shift;
    $self->follow_waypoints;
}

1;


