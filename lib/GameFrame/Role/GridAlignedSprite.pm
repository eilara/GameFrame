package GameFrame::Role::GridAlignedSprite;

use Moose::Role;
use aliased 'GameFrame::Grid::Markers';

with 'GameFrame::Role::Sprite';

has markers => (
    is       => 'ro',
    required => 1,
    isa      => Markers,
    handles  => [qw(cell_center_x cell_center_y)],
);

around _update_x => sub {
    my ($orig, $self) = @_;
    my $center = $self->cell_center_x($self->x);
    $center -= $self->w / 2 if $self->centered;
    $self->sprite_x($center);
};

around _update_y => sub {
    my ($orig, $self) = @_;
    my $center = $self->cell_center_y($self->y);
    $center -= $self->h / 2 if $self->centered;
    $self->sprite_y($center);
};

1;


