package GameFrame::Role::Positionable;

# role for object that can be positioned
# required constructor argument xy
# you can override xy_trigger which will be called
# when position is changed
# HACK underscore prefix return Vector2D, no underscore return array ref
#      because SDL methods cant take Vector2D, which they should

use Moose::Role;
use GameFrame::Types qw(Vector2D);

has xy_vec => (is => 'rw', isa => Vector2D, required => 1, coerce => 1,
               trigger => sub { shift->xy_trigger });

around BUILDARGS => sub {
    my ($orig, $class, %args) = @_;

    if (exists($args{x}) && exists($args{y})) {
        $args{xy} = [$args{x}, $args{y}];
    }

    if (my $xy = delete $args{xy}) {
        $args{xy_vec} = $xy;
    }

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

