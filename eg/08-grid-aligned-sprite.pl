#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../lib";

# how to work with grid aligned sprites
# move mouse around to move sprite
# click to drop a sprite at current mouse position
#
# just like the sprite example, except the sticky sprite is grid aligned
# grid aligned- aligned to the center of cells in the grid defined
# by the Markers object
# with centered => 1 the center of the sprite is the center of the cell
# with centered => 0 the top left of the sprite is the center of the cell
#
# note that GridMoveAroundSprite does Draggable, so we don't need
# to implement on_mouse_motion

package GameFrame::eg::GridStickySprite;
use Moose;
with 'GameFrame::Role::GridAlignedSprite';

# ------------------------------------------------------------------------------

package GameFrame::eg::GridMoveAroundSprite;
use Moose;

has children => (is => 'ro', required =>1, default => sub { [] });
has markers  => (is => 'ro', required => 1);

with qw(
    GameFrame::Role::Draggable
    GameFrame::Role::Sprite
);

sub on_mouse_button_up {
    my $self = shift;
    push @{$self->children}, GameFrame::eg::GridStickySprite->new(
        xy       => $self->xy,
        size     => [22, 26],
        image    => 'arrow',
        layer    => 'middle',
        centered => 1,
        markers  => $self->markers,  
    );
}

# ------------------------------------------------------------------------------

package main;
use strict;
use warnings;
use FindBin qw($Bin);
use aliased 'GameFrame::App';
use aliased 'GameFrame::Grid::Markers';

my $app = App->new(
    title       => 'Grid Aligned Sprite',
    bg_color    => 0x0,
    hide_cursor => 1,

    layer_manager_args => [layers => [qw(middle top)]],
);

my $markers = Markers->new(size => $app->size, xy => [0, 0], spacing => 32);

my $sprite = GameFrame::eg::GridMoveAroundSprite->new(
    rect     => [100, 100, 22, 26],
    image    => 'arrow',
    layer    => 'top',
    centered => 1,
    markers  => $markers,
);

$app->run;


