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
    $self->accept_death;
    $self->sequence('leave_grid');
    $self->animate_sprite(
        from_to  => [1, 7], # from frame 1 to 4 in the sequence
        duration => 0.5,
    );
 }

1;


