package GameFrame::Role::Positionable;

# role for object that can be positioned
# required constructor argument xy
# you can override xy_trigger which will be called
# when position is changed
# HACK underscore prefix return Vector2D, no underscore return array ref
#      because SDL methods cant take Vector2D, for which I should send a patch

use Moose::Role;
use GameFrame::Types qw(Vector2D);

has xy_vec => (is => 'rw', isa => Vector2D, required => 1, coerce => 1,
               trigger => sub { shift->xy_trigger });

around BUILDARGS => sub {
    my ($orig, $class, %args) = @_;

    if (exists($args{x}) && exists($args{y})) {
        $args{xy} = [$args{x}, $args{y}];
    }

    $args{xy_vec} = delete $args{xy};
    return $class->$orig(%args);
};

sub xy {
    my $self = shift;
    my $xy = $self->xy_vec;
    return [@$xy] unless @_;
    $xy->[0] = $_[0]->[0];
    $xy->[1] = $_[0]->[1];
    $self->xy_trigger;
}
 
sub x {
    my $self = shift;
    my $xy = $self->xy_vec;
    return $xy->[0] unless @_;
    $xy->[0] = $_[0];
    $self->xy_trigger;
}

sub y {
    my $self = shift;
    my $xy = $self->xy_vec;
    return $xy->[1] unless @_;
    $xy->[1] = $_[0];
    $self->xy_trigger;
}

sub xy_trigger {}

1;

__END__


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

sub self_translate_point {
    my ($self, @args) = @_;
    $self->xy($self->translate_point(@args));
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

1;

__END__


# use Math::Trig;
use GameFrame::Util qw(distance);
