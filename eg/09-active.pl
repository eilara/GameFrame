#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../lib";

# a simple active object
# watch the circle radius change twice, then disappear
#
# active objects have their own thread in which they run
# they must implement start, which runs in their own thread
# the start() method of your active object will be called
# after construction by the Coro scheduler on a new thread
#
# whats unique about them, is that they can block, using
# sleep() or wait for signal
# 
# usually you dont use sleep(), instead use the high level
# timer based methods from Animated or Movable roles, that are
# featured in the next demos
#
# sleep() is problematic because you can't stop it easily,
# and it does not support the pause feature
# when we have elastic time support, it will not support that either ;)

package GameFrame::eg::ActiveCircle;
use Moose;
use Coro::Timer qw(sleep);

has radius => (is => 'rw', default => 100);

with qw(
    GameFrame::Role::Paintable
    GameFrame::Role::Positionable
    GameFrame::Role::Active
);

sub start {
    my $self = shift;
    for (1..2) {
        for my $r (1..100) {
            $self->radius(101 - $r);
            sleep 1/60;
        }
        for my $r (1..100) {
            $self->radius($r);
            sleep 1/60;
        }
    }
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
    title    => 'Active Object',
    bg_color => 0x0,
);

# dont keep a ref around, so that it will vanish after animation is done
GameFrame::eg::ActiveCircle->new(xy => [100, 100]);

$app->run;


