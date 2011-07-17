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

with qw(
    GameFrame::Role::AnimatedSprite
    GameFrame::Role::SDLEventHandler
    GameFrame::Role::Active
);

sub start {
    my $self = shift;
    while (1) {
        # note frames start with 1
        $self->animate_sprite(
            from_to  => [1,4],
            duration => 2,
        );
    }
}

sub on_mouse_button_up {
    my $self = shift;
    $self->sequence(
        $self->sequence eq 'digits'? 'letters': 'digits'
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

GameFrame::eg::AnimatedSprite->new(
    rect      => [100, 100, 22, 22],
    image     => 'animated',
    sequence  => 'digits',
    sequences => {
        digits  => [ [0,0], [1,0], [2,0], [3,0] ],
        letters => [ [0,1], [1,1], [2,1], [3,1] ],
    },
);

$app->run;


