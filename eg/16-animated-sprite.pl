#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../lib";

# how to create animated sprites
# click mouse anywhere to change next animation sequence
#
# note how we setup the sprite images in the constructor, naming each sequence
# then to animate, we use animate_sprite

package GameFrame::eg::AnimatedSprite;
use MooseX::Types::Moose qw(Str);
use Moose;

has sequence => (is => 'rw', required => 1);

with qw(
    GameFrame::Role::SDLEventHandler
    GameFrame::Role::AnimatedSprite
    GameFrame::Role::Active
);

sub start {
    my $self = shift;
    while (1) {
        $self->animate_sprite(
            sequence => $self->sequence,
            frames   => 4,
            sleep    => 0.2,
        );
    }
}

sub on_mouse_button_up {
    my $self = shift;
    $self->sequence(
        $self->sequence eq 'left_right'? 'corners': 'left_right'
    );
}

# ------------------------------------------------------------------------------

package main;
use strict;
use warnings;
use FindBin qw($Bin);
use aliased 'GameFrame::App';

my $app = App->new(
    title    => 'Animated Sprite',
    bg_color => 0x0,
);

my $sprite = GameFrame::eg::AnimatedSprite->new(
    xy       => [100, 100],
    sequence => 'left_right',
    image    => {
        file      => 'animated',
        size      => [22, 22],
        sequences => {
            left_right => [ [0,0], [1,0], [2,0], [3,0] ],
            corners    => [ map { [$_,1] } 0..3 ],
        },
    },
);

$app->run;


