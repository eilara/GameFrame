#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../lib";

# how to create objects that live, can be hit, and then die
# click mouse to damage the cursor monster until it dies

package GameFrame::eg::LivingSprite;
use Moose;
use Math::Vector::Real;

with qw(
    GameFrame::Role::SDLEventHandler
    GameFrame::Role::Sprite
    GameFrame::Role::Movable
    GameFrame::Role::Living
    GameFrame::Role::HealthBar
);

sub on_mouse_button_up { shift->hit(30) }

sub on_death {
    my $self = shift;
    $self->set_to([100,480]);
    $self->start_motion; # returns immediately, motion starts async in Coro thread
}

after paint => sub {
    my $self = shift;
    my $pos = $self->xy_vec + V(-5, 25);
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

my $sprite = GameFrame::eg::LivingSprite->new(
    rect       => [100, 100, 22, 26],
    speed      => 200, # for death animation
    start_hp   => 100,
    image      => 'arrow',
    health_bar => [0, -10, 22, 2],
);

$app->run;


