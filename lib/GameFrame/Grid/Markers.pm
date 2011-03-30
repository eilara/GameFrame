package GameFrame::Grid::Markers;

# draws grid markers and converts from xy -> cell index

use Moose;
use MooseX::Types::Moose qw(Bool Int ArrayRef);
use aliased 'GameFrame::Grid::Markers::Axis';

has spacing => (
    is       => 'ro',
    required => 1,
    isa      => Int,
    default  => 24,
);

has grid_color => (
    is       => 'ro',
    required => 1,
    isa      => Int,
    default  => 0x1F1F1FFF,
);

with 'GameFrame::Role::Rectangle';

with qw(
    GameFrame::Role::Paintable
    GameFrame::Role::Rectangular
);

for my $ax (qw(x y)) {
    my $col_or_row = $ax eq 'x'? 'col': 'row';
    has "${ax}_axis" => (
        is         => 'ro',
        lazy_build => 1,
        isa        => Axis,
        handles    => {"${col_or_row}_marks" => 'marks'},
    );
}
    
sub _build_x_axis { shift->_build_axis('w') }
sub _build_y_axis { shift->_build_axis('h') }
    
sub _build_axis {
    my ($self, $accessor) = @_;
    return Axis->new(
        size    => $self->$accessor,
        spacing => $self->spacing,
    );
}

sub compute_cell_pos {
    my ($self, $xy) = @_;
    my $s = $self->spacing;
    return [int( $xy->[0] / $s ), int( $xy->[1] / $s )];
}

sub cell_center_x {
    my ($self, $x) = @_;
    my $offset_x = $self->x;
    my $s = $self->spacing;
    return $offset_x + int( ($x - $offset_x) / $s ) * $s + $s / 2;
}

sub cell_center_y {
    my ($self, $y) = @_;
    my $offset_y = $self->y;
    my $s = $self->spacing;
    return $offset_y + int( ($y - $offset_y) / $s ) * $s + $s / 2;
}

sub paint {
    my ($self, $surface) = @_;
    my ($x, $y, $w, $h, $c) = (@{$self->xy}, @{$self->size}, $self->grid_color);
    $surface->draw_line([$_, $y], [$_, $y + $h], $c, 0) for @{ $self->col_marks };
    $surface->draw_line([$x, $_], [$x + $w, $_], $c, 0) for @{ $self->row_marks };
}

1;

