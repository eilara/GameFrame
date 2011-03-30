#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../lib";

# example of pausing all active objects
# watch the circle radius change, then click mouse button
# to pause/resume
#
# just like the active example, but with pause feature

package GameFrame::eg::PauseAnimatedCircle;
use Moose;
use GameFrame::Time qw(animate pause_resume);

has radius => (is => 'rw', required =>1, default => 1);

with qw(
    GameFrame::Role::Paintable
    GameFrame::Role::Active
    GameFrame::Role::SDLEventHandler
);

sub start {
    my $self = shift;
    while (1) {
        animate
            type  => [linear => 1, 100, 50],
            on    => [radius => $self],
            sleep => 1/20;
    }
}

sub on_mouse_button_up { pause_resume }

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
    title    => 'Active Object Pause',
    bg_color => 0x0,
);

my $circle = GameFrame::eg::PauseAnimatedCircle->new;

$app->run;


