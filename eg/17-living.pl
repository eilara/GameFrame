#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../lib";

# how to create objects that live, can be hit, and then die
# click mouse to damage the cursor monster until it dies

package GameFrame::eg::LivingSprite;
use Moose;
use GameFrame::Util::Vectors;

with map { "GameFrame::Role::$_" } qw(
    SDLEventHandler
    Sprite
    Movable
    Living
    HealthBar
    Active
);

sub start {
    my $self = shift;
    $self->wait_for_death;
    $self->move_to([100,480]);
}

sub on_mouse_button_up { shift->hit(30) }

after paint => sub {
    my $self = shift;
    # we want the HP text to show (-7,27) pixels to the
    # right/bottom of my top left corner
    my $pos = $self->xy_vec + V(-7, 27);
    $self->draw_gfx_text(
        [@$pos],
        0xFFFFFFFF,
        "HP=". $self->hp,
    );
};

# ------------------------------------------------------------------------------

package main;
use strict;
use warnings;
use FindBin qw($Bin);
use aliased 'GameFrame::App';

my $app = App->new(
    title    => 'Living Example',
    bg_color => 0x0,
);

GameFrame::eg::LivingSprite->new(
    rect       => [100, 100, 22, 22],
    speed      => 100, # for death animation
    start_hp   => 100,
    image      => 'mole',
    health_bar => [0, -8, 22, 2],
);

$app->run;


