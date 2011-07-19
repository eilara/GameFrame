#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../lib";

# how to use the grid to check/query cells for grid-based games
# click on the mole to have it disappear and reappear in random cell

package GameFrame::eg::GridMole;
use Moose;

with 'GameFrame::Role::GridAlignedSprite';

# ------------------------------------------------------------------------------

package GameFrame::eg::GridCursor;
use Moose;

has [qw(mole grid)] => (is => 'ro', required => 1);

with qw(
    GameFrame::Role::Sprite
    GameFrame::Role::Cursor
);

# if clicking on a cell with a mole, move the mole to a new random cell
sub on_mouse_button_up {
    my $self = shift;
    my $grid = $self->grid;
    return if $grid->is_cell_empty_at($self->xy);

    my $mole = $self->mole;
    my $xy = [int(rand(640)), int(rand(480))];
    $grid->clear_cell_at($self->xy);
    $grid->set_cell_contents_at($xy, $mole);
    $mole->xy( $grid->cell_center_xy($xy) );
}

# ------------------------------------------------------------------------------

package main;
use strict;
use warnings;
use FindBin qw($Bin);
use aliased 'GameFrame::App';
use aliased 'GameFrame::Grid::Markers';
use aliased 'GameFrame::Grid';

my $app = App->new(
    title       => 'Grid',
    bg_color    => 0x0,
    hide_cursor => 1,

    layer_manager_args => [layers => [qw(items cursor)]],
);

my $markers = Markers->new(xy => [0, 0], size => $app->size, spacing => 80);

my $mole = GameFrame::eg::GridMole->new(
    rect     => [0, 0, 22, 22],
    image    => 'mole',
    layer    => 'items',
    centered => 1,
    markers  => $markers,
);

my $grid = Grid->new(
    markers    => $markers,
    init_cells => [[0, 0, $mole]],
);

my $cursor = GameFrame::eg::GridCursor->new(
    rect     => [0, 0, 22, 26],
    image    => 'arrow',
    layer    => 'cursor',
    mole     => $mole,
    grid     => $grid,
);

$app->run;





