package GameFrame::Role::GridAlignedSprite;

use Moose::Role;
use aliased 'GameFrame::Grid::Markers';

with 'GameFrame::Role::Sprite';

has markers => (
    is       => 'ro',
    required => 1,
    isa      => Markers,
    handles  => [qw(cell_center_xy)],
);

around xy_trigger => sub {
    my ($orig, $self) = @_;
    my $xy = $self->cell_center_xy($self->_actual_xy) ;
    $xy -= $self->_size / 2 if $self->is_centered;
    my $sprite = $self->sprite;
    $sprite->x($xy->[0]);
    $sprite->y($xy->[1]);
};

1;


