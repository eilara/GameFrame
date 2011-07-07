#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../lib";

# example of pausing all active objects
# watch the circle radius change, then click mouse button
# to pause/resume

package GameFrame::eg::PauseAnimatedCircle;
use Moose;
use MooseX::Types::Moose qw(Int);
use aliased 'GameFrame::Role::Animation';

has radius    => (is => 'rw', isa => Int  , default  => 1);
has animation => (is => 'ro', isa => Animation, lazy_build => 1, handles => Animation);

sub _build_animation {
    shift->create_animation({
        attribute => 'radius',
        duration  => 3,
        to        => 100,
        bounce    => 1,
        forever   => 1,
    });
}

with qw(
    GameFrame::Role::Paintable
    GameFrame::Role::Positionable
    GameFrame::Role::SDLEventHandler
    GameFrame::Role::Animated
);

use Coro;
use Coro::EV;
use EV;

sub start {
    my $self = shift;
    $self->start_animation;
    $self->wait_for_animation_complete; # block forever, because animation
                                        # is forever
}

sub on_mouse_button_up {
    my $self = shift;
    my $is_active = $self->is_animation_started;
    my $method = ($is_active? 'pause': 'resume'). '_animation';
    $self->$method;
}

sub paint {
    my $self = shift;
    $self->draw_circle_filled([200, 200], $self->radius, 0xFFFFFFFF, 1);
}

# ------------------------------------------------------------------------------

package main;
use strict;
use warnings;
use FindBin qw($Bin);
use aliased 'GameFrame::App';

my $app = App->new(
    title    => 'Animation Pause',
    bg_color => 0x0,
);

my $circle = GameFrame::eg::PauseAnimatedCircle->new
    (xy => [100, 100]);

$app->run;


