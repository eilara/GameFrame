package GameFrame::Role::Figure;

# a paintable positionable thing with an angle
# will be rotated by the angle when drawn

use Moose::Role;
use Math::Trig;

has angle => (is => 'rw', default => 0);

with qw(
    GameFrame::Role::Paintable
    GameFrame::Role::Positionable
);

sub draw_polygon {
    my ($self, $surface, $color, @points) = @_;
    my $last_point = shift @points;
    push @points, $last_point; # make it a closed polygon
    for my $point (@points) {
        $self->draw_line
            ($surface, $color, $last_point, $point);
        $last_point = $point;
    }
}

# draws a line from 2 points defined by an angle and
# a distance from my xy
sub draw_line {
    my ($self, $surface, $color, $from, $to) = @_;
    my ($a1, $d1, $a2, $d2) = (@$from, @$to);
    $surface->draw_line(
        $self->translate_point_by_angle($a1 + $self->angle, $d1),
        $self->translate_point_by_angle($a2 + $self->angle, $d2),
        $color,
        1,
    );
}

sub translate_point_by_distance {
    my ($self, $distance) = @_;
    return $self->translate_point_by_angle($self->angle, $distance);
}

1;


