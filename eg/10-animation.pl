#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../lib";

# examples of animations

package GameFrame::eg::AnimatedCircle;
use Moose;

has radius => (is => 'rw', default  => 1);
has spec   => (is => 'ro', required => 1); # animation spec

with qw(
    GameFrame::Role::Paintable
    GameFrame::Role::Positionable
    GameFrame::Role::Animated
);

sub start {
    my $self = shift;
    $self->animate($self->spec);
}

sub paint {
    my $self = shift;
    $self->draw_circle_filled($self->xy, $self->radius, 0xFFFFFFFF, 1);
}

# ------------------------------------------------------------------------------

package main;
use strict;
use warnings;
use FindBin qw($Bin);
use aliased 'GameFrame::App';

my $app = App->new(
    title    => 'Animated Role',
    bg_color => 0x0,
);

GameFrame::eg::AnimatedCircle->new(
    xy   => [100, 100],
    spec => {
        attribute => 'radius',
        duration  => 1,
        from_to   => [1, 100],
        forever   => 1,
    },
);

# or animate twice, default repeat is once
# note this time the animation goes the other way: 100 to 1
GameFrame::eg::AnimatedCircle->new(
    xy   => [100, 300],
    spec => {
        attribute => 'radius',
        duration  => 2,
        from_to   => [100, 1],
        repeat    => 2,
    },
);

# tell it to bounce
GameFrame::eg::AnimatedCircle->new(
    xy   => [300, 100],
    spec => {
        attribute => 'radius',
        duration  => 2,
        from_to   => [40, 60],
        bounce    => 1,
        forever   => 1,
    },
);

# animate more than one attribute at once
GameFrame::eg::AnimatedCircle->new(
    xy   => [300, 300],
    spec => [
        {
            attribute => 'radius',
            duration  => 1,
            from_to   => [10, 70],
            bounce    => 1,
            forever   => 1,
        },
        {
            attribute => 'x',
            duration  => 2,
            from_to   => [240, 360],
            bounce    => 1,
            forever   => 1,
        },
    ],
);

$app->run;

__END__

$app->run;


