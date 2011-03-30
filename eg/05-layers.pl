#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../lib";

# how to layer things
# click screen to draw circle on a random layer

# about layers
# when you want paintables to appear in a specific z-order you need layers
# with this feature you can set the z-order of every paintable
# to use it:
# 1- set the layer names in the App constructor, in back-to-front order
#    by setting the layer key of layer_manager_args
#    in the example below we create 3 layers
# 2- provide a layer name in the Paintable constructor
#    in the example we create each layer circle in a random layer    
# 3- a layer called background is automatically created for you
#    it is lowest layer and default layer for paintables with no layer

package GameFrame::eg::LayerCircle;
use Moose;

with 'GameFrame::Role::Point';

with qw(
    GameFrame::Role::Paintable
    GameFrame::Role::Positionable
);

has color => (is => 'ro');

sub paint {
    my ($self, $surface) = @_;
    my $xy = $self->xy;
    $surface->draw_circle_filled($xy, 100, $self->color, 1);
    $surface->draw_circle($xy, 100, $self->color + 0xFF - 0x4F, 1);
}

# ------------------------------------------------------------------------------

package GameFrame::eg::LayerEventHandler;
use Moose;

with 'GameFrame::Role::SDLEventHandler';

has circles => (is => 'ro', default => sub { [] });

sub on_mouse_button_up {
    my ($self, $x, $y) = @_;

    my $rand = int rand 3;
    my $color = [0xFF00004F, 0x00FF004F, 0x0000FF4F]->[$rand];
    my $layer = ([qw(red green blue)]->[$rand]). '_layer';

    push @{ $self->circles }, GameFrame::eg::LayerCircle->new(
        xy    => [$x, $y],
        color => $color,
        layer => $layer,
    );
}

# ------------------------------------------------------------------------------

package main;
use strict;
use warnings;
use aliased 'GameFrame::App';

my $app = App->new(
    title    => 'Layers',
    bg_color => 0x0,

    layer_manager_args => [layers => [qw(
        red_layer green_layer blue_layer
    )]],
);

my $event_handler = GameFrame::eg::LayerEventHandler->new;

$app->run;


