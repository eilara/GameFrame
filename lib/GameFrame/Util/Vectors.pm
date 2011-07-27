package GameFrame::Util::Vectors;

use strict;
use warnings;
use Math::Vector::Real;
use Math::Trig;
use Collision::2D ':all';
use base 'Exporter';

our @EXPORT = qw(pi V VP angle_between random_edge_vector
                 detect_dynamic_collision normalize_vector);

# polar vector: angle and distance
sub VP {
    my ($angle, $dist) = @_;
    return V( 
        $dist * cos($angle),
        $dist * sin($angle),
    );
}

# vector to random spot on edge of box with given w and h
sub random_edge_vector($) {
    my $v = shift;
    my ($w, $h) = @$v;
    my $x_point = int rand $w * 2 + $h * 2;
    my $y_point = $x_point - $w * 2;
    my ($x, $y) = $y_point < 0?
        ($x_point % $w, $x_point < $w? 0: $h):
        ($y_point < $h? 0: $w, $y_point % $h);
    return V($x, $y);
}

sub angle_between($$) {
    my ($v1, $v2) = @_;
    my ($dx, $dy) = @{ $v2 - $v1 };
    # $v2 is too close to $v1 to compute angle
    return undef if abs($dx) < 0.5 and abs($dy) < 0.5;
    return atan2($dy, $dx);
}

sub normalize_vector($) {
    my ($v) = @_;
    return $v / abs($v);
}

my $Collision_Detection_Dispath = {
    circle_to_circle => \&detect_dynamic_collision_circle_to_circle,
};

sub detect_dynamic_collision($%) {
    my ($type, @args) = @_;
    my $code = $Collision_Detection_Dispath->{$type};
    $code->(@args);
}

sub detect_dynamic_collision_circle_to_circle {
    my ($c1, $c2, $interval) = @_;
    ($c1, $c2) = map { prepare_circle($_) } $c1, $c2;
    my $collision = dynamic_collision($c1, $c2, interval => $interval);
    return $collision? $collision->time: undef;
}

sub prepare_circle {
    my $c = shift;
    my ($c_xy, $c_v) = ($c->xy_vec, $c->velocity);
    return hash2circle ({x=>$c_xy->[0], y=>$c_xy->[1], xv=>$c_v->[0],
                         yv=>$c_v->[1], radius => $c->radius});
}
