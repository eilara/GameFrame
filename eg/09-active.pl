#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../lib";

# a simple active object
# watch the circle radius change
#
# active objects have their own thread and call blocking
# functions from GameFrame::Time, like animate(), used below
# the start() method of your active object will be called
# after construction by the Coro scheduler on a new thread

package GameFrame::eg::AnimatedCircle;
use Moose;
use GameFrame::Time qw(animate);

has radius => (is => 'rw', default => 1);

with qw(
    GameFrame::Role::Paintable
    GameFrame::Role::Active
);

sub start {
    my $self = shift;
    while (1) {
        animate
            type  => [linear => 1, 100, 50], # 1 to 100 in 50 steps
            on    => [radius => $self],      # animate radius property
            sleep => 1/20;                   # sleep 1/20th of a sec
    }
}

sub paint {
    my ($self, $surface) = @_;
    $surface->draw_circle_filled([200, 200], $self->radius, 0xFFFFFFFF, 1);
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

my $circle = GameFrame::eg::AnimatedCircle->new;

$app->run;


