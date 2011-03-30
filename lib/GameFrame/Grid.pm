package GameFrame::Grid;

# the grid:
#    * handles finding cells by xy
#    * keeps the grid cells and lets you set/clear/query the cell contents

use Moose;
use MooseX::Types::Moose qw(ArrayRef Int);
use aliased 'GameFrame::Grid::Markers';
use aliased 'GameFrame::Grid::Cell';

has markers => (
    is       => 'ro',
    isa      => Markers,
    required => 1,
    handles  => [qw(compute_cell_pos col_marks row_marks)],
);

has init_cells => (is => 'ro', isa => ArrayRef[ArrayRef], default => sub { [] });
has cells      => (is => 'ro', isa => ArrayRef[ArrayRef[Cell]], lazy_build => 1);

sub _build_cells {
    my $self = shift;
    my ($rows, $cols) = ($self->row_marks, $self->col_marks);
    my $cells = [map {[map { Cell->new } @$rows]} @$cols];
    $self->fill_init_cells($cells);
    return $cells;
}

sub fill_init_cells {
    my ($self, $cells) = @_;
    for my $tuple (@{ $self->init_cells }) {
        my ($row, $col, $contents) = @$tuple;
        $cells->[$col]->[$row]->contents($contents);
    }
}

sub clear_cell_at {
    my ($self, $xy) = @_;
    $self->find_cell_at($xy)->clear;
}

sub set_cell_contents_at {
    my ($self, $xy, $contents) = @_;
    $self->find_cell_at($xy)->contents($contents);
}

sub is_cell_empty_at {
    my ($self, $xy) = @_;
    return $self->find_cell_at($xy)->is_empty;
}

sub find_cell_at {
    my ($self, $xy) = @_;
    my ($col, $row) = @{ $self->compute_cell_pos($xy) };
    return $self->cells->[$col]->[$row];
}

1;

__END__

#    find_cell_by_xy compute_cell_center_by_xy


sub _build_cells {
    my $self = shift;
    my ($rows, $cols) = ($self->row_marks, $self->col_marks);
    my $cells = [map {[map { Grid::Cell->new } @$rows]} @$cols];

    # fill path into cells so that we can answer can_build on a cell
    my @last_wp_cell;
    for my $wp (@{ $self->points_px }) {
        my ($col, $row) = @{ $self->find_cell($wp->[0], $wp->[1]) };
        if (@last_wp_cell) {
            my ($lcol, $lrow) = (@last_wp_cell);
            for my $path_col (min($lcol, $col)..max($lcol, $col)) {
                for my $path_row (min($lrow, $row)..max($lrow, $row)) {
                    $cells->[$path_col]->[$path_row]->set_as_path;
                }
            }
        }
        @last_wp_cell = ($col, $row);
        $cells->[$col]->[$row]->set_as_waypoint;
    }

    return $cells;
}

sub add_tower {
    my ($self, $x, $y, $tower) = @_;
    my $cell = $self->get_cell($x, $y);
    return unless $cell;
    $cell->set_as_tower($tower);
}

sub select_tower {
    my ($self, $x, $y) = @_;
    my $cell = $self->get_cell($x, $y);
    return unless $cell && $cell->is_tower;
    my $tower = $cell->contents;
    $tower->set_selected;
    return $tower;
}

sub unselect_tower {
    my ($self, $tower) = @_;
    my $cell = $self->get_cell(@{$tower->xy});
    return unless $cell && $cell->is_tower;
    $tower->set_unselected;
    return $tower;
}

# is this a type of cell that cursor shadow would look nice on
sub should_show_shadow {
    my ($self, $x, $y) = @_;
    my $cell = $self->get_cell($x, $y);
    return 0 unless $cell;
    return
        $cell->has_contents
            ? $cell->is_tower? 0: 1
            : 1;
}

sub get_cell {
    my ($self, $x, $y) = @_;
    my ($col, $row) = @{ $self->find_cell($x, $y) };
    my $cells = $self->cells->[$col];
    return undef unless $col; # out of screen
    my $cell = $cells->[$row];
    return undef unless $row; # out of screen
    return $cell;
}

