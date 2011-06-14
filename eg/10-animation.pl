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
    $self->draw_circle($self->xy, $self->radius, 0xFFFFFFFF, 1);
}

# ------------------------------------------------------------------------------

package main;
use strict;
use warnings;
use FindBin qw($Bin);
use aliased 'GameFrame::App';
use Math::Vector::Real; # for the V() constructor

my $app = App->new(
    title    => 'Animated Role',
    bg_color => 0x0,
);

GameFrame::eg::AnimatedCircle->new(
    xy   => [50, 50],
    spec => {
        attribute => 'radius',
        duration  => 1,
        from_to   => [1, 50],
        forever   => 1,
    },
);

# or animate twice, default repeat is once
# note this time the animation goes the other way: 50 to 1
GameFrame::eg::AnimatedCircle->new(
    xy   => [150, 50],
    spec => {
        attribute => 'radius',
        duration  => 2,
        from_to   => [50, 1],
        repeat    => 2,
    },
);

# tell it to bounce, auto-reversing itself
GameFrame::eg::AnimatedCircle->new(
    xy   => [250, 50],
    spec => {
        attribute => 'radius',
        duration  => 2,
        from_to   => [10, 50],
        bounce    => 1,
        forever   => 1,
    },
);

# animate more than one attribute at once
GameFrame::eg::AnimatedCircle->new(
    xy   => [450, 50],
    spec => [
        {
            attribute => 'radius',
            duration  => 2,
            from_to   => [1, 50],
            bounce    => 1,
            forever   => 1,
        },
        {
            attribute => 'x',
            duration  => 1,
            from_to   => [450, 350],
            bounce    => 1,
            forever   => 1,
        },
    ],
);

# animate 2D attributes, e.g. xy
GameFrame::eg::AnimatedCircle->new(
    xy     => [520, 20],
    radius => 20,
    spec   => {
        attribute => 'xy_vec',
        duration  => 2,
        from_to   => [V(520, 20), V(620, 80)],
        bounce    => 1,
        forever   => 1,
    },
);

$app->run;

__END__

$app->run;


