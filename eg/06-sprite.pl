#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../lib";

# how to create sprites
# move mouse around to move sprite
# click to drop a sprite at current mouse position
#
# note that StickySprites are created centered on xy
# while MoveAroundSprite is created with xy at top left

package GameFrame::eg::StickySprite;
use Moose;
with 'GameFrame::Role::Sprite';

# ------------------------------------------------------------------------------

package GameFrame::eg::MoveAroundSprite;
use Moose;

has children => (is => 'ro', required =>1, default => sub { [] });

with qw(
    GameFrame::Role::SDLEventHandler
    GameFrame::Role::Sprite
);

# hide/show this cursor when entering/leaving app
sub on_app_mouse_focus { shift->is_visible(pop) }

sub on_mouse_motion {
    my ($self, $x, $y) = @_;
    $self->x($x);
    $self->y($y);
}

sub on_mouse_button_up {
    my $self = shift;
    push @{$self->children}, GameFrame::eg::StickySprite->new(
        xy       => $self->xy,
        image    => 'arrow',
        layer    => 'middle',
        centered => 1,
    );
}

# ------------------------------------------------------------------------------

package main;
use strict;
use warnings;
use FindBin qw($Bin);
use aliased 'GameFrame::App';

my $app = App->new(
    title       => 'Sprite',
    bg_color    => 0x0,
    hide_cursor => 1,
    resources   => "$Bin/resources",

    layer_manager_args => [layers => [qw(middle top)]],
);

my $sprite = GameFrame::eg::MoveAroundSprite->new(
    xy    => [100, 100],
    image => 'arrow',
    layer => 'top',
);

$app->run;


