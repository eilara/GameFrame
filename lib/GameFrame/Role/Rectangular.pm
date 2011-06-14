package GameFrame::Role::Rectangular;

# role for rectangular positionable objects
# required constructor argument size
# or you can specify rect array ref instead, with both xy and size
# also features centering, configurable with is_centered attribute:
# use xy to get top left corner, always
# use center_xy to get center, always
# use actual_xy to get corner or center depending on centered attribute
# so usualy you want to use actual_xy which will just DWIM
#
# TODO not _ prefix but _vec suffix for versions which deal with vectors and not arrays

use Moose::Role;
use MooseX::Types::Moose qw(Bool);
use GameFrame::Types qw(Vector2D);

has _size       => (is => 'ro', isa => Vector2D, required => 1, coerce  => 1);
has is_centered => (is => 'ro', isa => Bool    , required => 1, default => 0);

with 'GameFrame::Role::Positionable';

around BUILDARGS => sub {
    my ($orig, $class, %args) = @_;
    if (my $rect = delete $args{rect}) {
        $args{xy}   = [ @$rect[0,1] ];
        $args{size} = [ @$rect[2,3] ];
    }
    $args{_size} = delete $args{size};
    return $class->$orig(%args);
};

sub size {
    my $self = shift;
    my $size = $self->_size;
    return [ @$size ] unless @_;
    $size->[0] = $_[0]->[0];
    $size->[1] = $_[0]->[1];
}
 
sub w {
    my $self = shift;
    my $size = $self->_size;
    return $size->[0] unless @_;
    $size->[0] = $_[0];
}

sub h {
    my $self = shift;
    my $size = $self->_size;
    return $size->[1] unless @_;
    $size->[1] = $_[0];
}

sub _center_xy {
    my $self = shift;
    return $self->xy_vec + $self->_size / 2;
}

sub center_xy {
    my $self = shift;
    return [@{ $self->_center_xy }];
}

sub _actual_xy {
    my $self = shift;
    return $self->is_centered? $self->_center_xy: $self->xy_vec;
}

sub actual_xy {
    my $self = shift;
    return $self->is_centered? $self->center_xy: $self->xy;
}

sub rect {
    my $self = shift;
    return [@{$self->_actual_xy}, @{$self->_size}];
}

1;

__END__

sub scale_rect {
    my ($self, $px) = @_;
    my $px2 = $px / 2;
    return [$self->x - $px2, $self->y - $px2, $self->w + $px, $self->h + $px];
}

