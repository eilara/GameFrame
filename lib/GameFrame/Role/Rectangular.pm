package GameFrame::Role::Rectangular;

# use x/y to get top left corner
# use center_x/y to get center
# use actual_x/y to get corner or center depending on centered attribute
# so usualy you want to use actual_x/actual_y which will just DWIM

use Moose::Role;
use MooseX::Types::Moose qw(Bool);

requires 'w', 'h';

has centered => (is => 'ro', isa => Bool, required => 1, default => 0);

with 'GameFrame::Role::Positionable';

# extract w and h if size given
around BUILDARGS => sub {
    my ($orig, $class, %args) = @_;
    my $size = $args{size};
    if ($size) {
        ($args{w}, $args{h}) = @$size;
    }
    return $class->$orig(%args);
};

sub size {
    my $self = shift;
    return [$self->w, $self->h] unless @_;
    my ($w, $h) = @{ shift() };
    $self->w($w);
    $self->h($h);
}

sub rect {
    my $self = shift;
    return [$self->actual_x, $self->actual_y, $self->w, $self->h];
}

sub actual_x {
    my $self = shift;
    return $self->centered? $self->center_x: $self->x;
}

sub actual_y {
    my $self = shift;
    return $self->centered? $self->center_y: $self->y;
}

sub center_x {
    my $self = shift;
    return $self->x - $self->w / 2;
}

sub center_y {
    my $self = shift;
    return $self->y - $self->h / 2;
}

sub to_string {
    my $self = shift;
    return 'x='.$self->x.', y='.$self->y.', w='.$self->w.', h='.$self->h;
}

1;

