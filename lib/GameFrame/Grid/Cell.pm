package GameFrame::Grid::Cell;

# a cell in the grid

use Moose;

has contents => (
    is        => 'rw',
    predicate => 'has_contents',
    clearer   => 'clear',
);

sub is_empty { !shift->has_contents }


1;

