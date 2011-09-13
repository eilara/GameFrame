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
has radius => (is => 'rw', isa => Int  , default  => 1);
has spec   => (is => 'ro', required => 1); # animation spec

with qw(
    GameFrame::Role::Paintable
    GameFrame::Role::Positionable
    GameFrame::Role::Animated
    GameFrame::Role::Active
);

sub start {
    my $self = shift;
    $self->animate($self->spec);
}

sub paint {
    my $self = shift;
    $self->draw_circle_filled($self->xy, $self->radius, 0xFFFFFFFF);
}

# ------------------------------------------------------------------------------

package main;
use strict;
use warnings;
use FindBin qw($Bin);
use aliased 'GameFrame::App';
use GameFrame::Util::Vectors; # for V() constructor and pi constant

my $app = App->new(
    title    => 'Animated Role',
    bg_color => 0x0,
);

# animate radius forever from 1 to 50
GameFrame::eg::AnimatedCircle->new(
    xy   => [50, 50],
    spec => {
        attribute => 'radius',
        duration  => 1,
        to        => 50,
        forever   => 1,
    },
);

# or animate twice, default repeat is once
# note this time the animation goes the other way: 50 to 1
GameFrame::eg::AnimatedCircle->new(
    xy     => [150, 50],
    radius => 50,
    spec   => {
        attribute => 'radius',
        duration  => 2,
        to        => 1,
        repeat    => 2,
    },
);

# tell it to bounce, auto-reversing itself
GameFrame::eg::AnimatedCircle->new(
    xy     => [250, 50],
    spec   => {
        attribute => 'radius',
        duration  => 2,
        from      => 10,
        to        => 50,
        bounce    => 1,
        forever   => 1,
    },
);

# animate more than one attribute at once
# note you can specify speed instead of duration
GameFrame::eg::AnimatedCircle->new(
    xy      => [450, 50],
    radius  => 1,
    spec    => [
        {
            attribute => 'radius',
            duration  => 2,
            to        => 50,
            bounce    => 1,
            forever   => 1,
        },
        {
            attribute => 'x',
            speed     => 100,
            to        => 350,
            bounce    => 1,
            forever   => 1,
        },
    ],
);

# animate 2D attributes, e.g. xy
# you could animate each property in 1D in parallel but this is more flexible
# note you must specify the 'to' as vectors not arrays
GameFrame::eg::AnimatedCircle->new(
    xy     => [520, 20],
    radius => 20,
    spec   => {
        attribute => 'xy',
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

# xyproperty is a 2D vector
# you can set 'curve' on the animation to animate the xy
# on some trajectory
# here the circle is moved in the same linear path as 
# the last example, but we add a sine curve to it, whith
# a frequency of 2 per duration of 2 seconds (a period of
# 1 second), and an amplitude of 50 pixels
GameFrame::eg::AnimatedCircle->new(
    xy     => [10, 300],
    radius => 10,
    spec   => {
        attribute  => 'xy',
        duration   => 2,
        to         => V(630, 300),
        bounce     => 1,
        forever    => 1,
        ease       => 'swing',
        curve      => 'sine',
        curve_args => [amp => 50, freq => 2],
    },
);

# another useful curve is the circle, the xy value is used
# as the center of the circle
GameFrame::eg::AnimatedCircle->new(
    xy     => [60, 420],
    radius => 10,
    spec   => {
        attribute  => 'xy',
        duration   => 4,
        bounce     => 1,
        forever    => 1,
        ease       => 'in_out_bounce',
        curve      => 'circle',
        curve_args => [radius => 50, begin => 2*pi*(1/8), end => 2*pi*(7/8)],
    },
);

# a spiral is a growing circle
GameFrame::eg::AnimatedCircle->new(
    xy     => [180, 415],
    radius => 5,
    spec   => {
        attribute  => 'xy',
        duration   => 4,
        bounce     => 1,
        forever    => 1,
        ease       => 'swing',
        curve      => 'spiral',
        curve_args => [
            begin_radius   => 1,
            end_radius     => 60,
            rotation_count => 3,
            begin_angle    => pi,
        ],
    },
);

$app->run;

__END__


