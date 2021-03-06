#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../lib";

# same as box-panel demo, only this time we route events to children.
# mouse over a panel to show mouse x/y inside that panel
#
# note only the moused-over event sink fires events
#
# to accept events from a box router parent, consume rectangular event sink role

package GameFrame::eg::EventSink;
use Moose;
use Math::Vector::Real;

has color => (is => 'ro', required => 1);

has last_mouse_xy => (is => 'rw', default => sub { [0, 0] });

with qw(
    GameFrame::Role::Paintable
    GameFrame::Role::Rectangular
    GameFrame::Role::Event::Sink::Rectangular
);

sub paint {
    my $self = shift;
    $self->draw_rect($self->rect, $self->color);

    my $pos = $self->xy_vec + V(20, 20);
    $self->draw_gfx_text(
        [@$pos],
        0x000000FF,
        join ',', @{$self->last_mouse_xy}
    );
}

sub on_mouse_motion {
    my ($self, $x, $y) = @_;
    $self->last_mouse_xy([$x, $y]);
}

# ------------------------------------------------------------------------------

package GameFrame::eg::EventRouter;
use Moose;

with 'GameFrame::Role::Event::BoxRouter';

# ------------------------------------------------------------------------------

package GameFrame::eg::TopLevelEventRouter;
use Moose;

with qw(
    GameFrame::Role::SDLEventHandler
    GameFrame::Role::Event::BoxRouter
);

# ------------------------------------------------------------------------------

package main;
use strict;
use warnings;
use FindBin qw($Bin);
use aliased 'GameFrame::App';

my $app = App->new(
    title    => 'Box Panel',
    bg_color => 0x0,
);

my $panel = GameFrame::eg::TopLevelEventRouter->new(
    orientation => 'vertical',
    rect        => [0, 0, 640, 480],
    child_defs  => [
        top_panel => {
            child_class => 'GameFrame::eg::EventSink',
            h           => 400, # w is implied by parent width
            color       => 0xFF0000FF,
        },
        bottom_panel => {
            child_class => 'GameFrame::eg::EventRouter',
            orientation => 'horizontal',
            h           => 80,
            child_defs  => [
                left_panel => {
                    child_class => 'GameFrame::eg::EventSink',
                    w           => 400, # h is implied by parent height
                    color       => 0x00FF00FF,
                },
                right_panel => {
                    child_class => 'GameFrame::eg::EventSink',
                    w           => 240,
                    color       => 0x0000FFFF,
                },
            ],
        },
    ],
);

$app->run;






