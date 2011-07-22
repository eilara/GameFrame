package GameFrame::Role::Figure;

# a paintable positionable thing with an angle
# will be rotated by the angle when drawn

use Moose::Role;
use GameFrame::Util::Vectors;

has angle => (is => 'rw', default => 0);

with qw(
    GameFrame::Role::Paintable
    GameFrame::Role::Positionable
);

sub draw_polygon_polar {
    my ($self, $color, @points) = @_;
    my $last_point = shift @points;
    push @points, $last_point; # make it a closed polygon
    for my $point (@points) {
        $self->draw_line_polar
            ($color, $last_point, $point);
        $last_point = $point;
    }
}

# draws a line from 2 points defined by an angle and
# a distance from my xy
sub draw_line_polar {
    my ($self, $color, $from, $to) = @_;
    my $angle = $self->angle;
    my $xy    = $self->xy_vec;
    $from     = $xy + VP($from->[0] + $angle, $from->[1]);
    $to       = $xy + VP(  $to->[0] + $angle,   $to->[1]);
    $self->draw_line([@$from], [@$to], $color, 1);
}

1;


