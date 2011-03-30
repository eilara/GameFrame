#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../lib";

# how to position things
# click screen to draw circle

package GameFrame::eg::ClickCircle;
use Moose;

with 'GameFrame::Role::Point'; # to get the x/y fields

with qw(
    GameFrame::Role::SDLEventHandler
    GameFrame::Role::Paintable
    GameFrame::Role::Positionable
);

sub on_mouse_button_up {
    my ($self, $x, $y) = @_;
    $self->xy([$x, $y]);
}

sub paint {
    my ($self, $surface) = @_;
    $surface->draw_circle($self->xy, 100, 0xFFFFFFFF, 1);
}

# ------------------------------------------------------------------------------

package main;
use strict;
use warnings;
use aliased 'GameFrame::App';

my $app = App->new(
    title    => 'Positionable',
    bg_color => 0x0, # setting bg_color on app will fill app with
                     # bg_color on every paint
);

my $paintable = GameFrame::eg::ClickCircle->new(x => 100, y => 100);

$app->run;


