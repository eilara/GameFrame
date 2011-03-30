package GameFrame::Role::Positionable;

use Moose::Role;
use Math::Trig;
use GameFrame::Util qw(distance);

requires 'x', 'y';

sub xy {
    my $self = shift;
    return [$self->x, $self->y] unless @_;
    my ($x, $y) = @{ shift() };
    $self->x($x);
    $self->y($y);
}

sub distance_to {
    my ($self, $to_xy) = @_;
    return distance(@{$self->xy}, @$to_xy);
}

sub translate_point {
    my ($self, $axis, $by_1, $by_2) = @_;
    my ($x, $y) = @{ $self->xy };
    return $axis eq 'x'? [$x + $by_1, $y]:
           $axis eq 'y'? [$x        , $y + $by_1]:
                         [$x + $by_1, $y + $by_2];
}

sub translate_point_by_angle {
    my ($self, $angle, $distance) = @_;
    my ($x, $y) = @{ $self->xy };
    return [
        $x + $distance * cos($angle),
        $y + $distance * sin($angle),
    ];
}

sub compute_angle_to {
    my ($self, $to_x, $to_y) = @_;
    my ($x, $y) = @{ $self->xy };
    my ($dx, $dy) = ($to_x - $x, $to_y - $y);
    # $to is too close to compute angle
    return undef if abs($dx) < 0.5 and abs($dy) < 0.5;
    return atan2($dy, $dx);
}

# extract x and y from xy if given
around BUILDARGS => sub {
    my ($orig, $class, %args) = @_;
    my $xy = $args{xy};
    if ($xy) {
        ($args{x}, $args{y}) = @$xy;
    }
    return $class->$orig(%args);
};

1;


