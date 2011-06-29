#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../lib";

# animation examples



# ------------------------------------------------------------------------------

# an animated circle

package GameFrame::eg::AnimatedCircle;
use Moose;
use MooseX::Types::Moose qw(Int);

# add Int constraint to turn on integer optimization in tweening
has radius => (is => 'rw', isa => Int, default  => 1);
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

# tell it to bounce, auto-reversing itself, and use speed to indicate
# absolute value of average speed, instead of duration
# radius changing in 20/sec will move 40 in 2 seconds, so this is the
# same as setting duration of 2
GameFrame::eg::AnimatedCircle->new(
    xy   => [250, 50],
    spec => {
        attribute => 'radius',
        speed     => 20,
        from_to   => [10, 50],
        bounce    => 1,
        forever   => 1,
    },
);

# animate more than one attribute at once
# note no need to set from_to, you can just specify 'to' and from
# will be computed from the target
GameFrame::eg::AnimatedCircle->new(
    xy   => [450, 50],
    spec => [
        {
            attribute => 'radius',
            duration  => 2,
            to        => 50,
            bounce    => 1,
            forever   => 1,
        },
        {
            attribute => 'x',
            duration  => 1,
            to        => 350,
            bounce    => 1,
            forever   => 1,
        },
    ],
);

# animate 2D attributes, e.g. xy_vec
# you could animate each property in 1D in parallel but this is more flexible
# note you must specify the from_to as vectors not arrays
GameFrame::eg::AnimatedCircle->new(
    xy     => [520, 20],
    radius => 20,
    spec   => {
        attribute => 'xy_vec',
        duration  => 2,
        to        => V(620, 80),
        bounce    => 1,
        forever   => 1,
    },
);

# default easing function is linear, set easing function with 'ease' key
GameFrame::eg::AnimatedCircle->new(
    xy     => [25, 125],
    radius => 25,
    spec   => {
        attribute => 'x',
        duration  => 2,
        to        => 615,
        bounce    => 1,
        forever   => 1,
        ease      => 'swing',
    },
);

# bounce is a nice easing function
GameFrame::eg::AnimatedCircle->new(
    xy     => [25, 200],
    radius => 25,
    spec   => {
        attribute => 'x',
        duration  => 4,
        to        => 615,
        bounce    => 1,
        forever   => 1,
        ease      => 'in_out_bounce',
    },
);

$app->run;

__END__



