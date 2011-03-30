#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../lib";

# same as box-panel demo, only this time we route events to children
# mouse over a panel to mouse x/y inside that panel
#
# note only the moused-over event sink fires events

package GameFrame::eg::EventSink;
use Moose;

has color => (is => 'ro', required => 1);

has last_mouse_xy => (is => 'rw', default => sub { [0, 0] });

with 'GameFrame::Role::Rectangle';
with qw(
    GameFrame::Role::Paintable
    GameFrame::Role::Rectangular
    GameFrame::Role::Event::Sink
);

sub paint {
    my ($self, $surface) = @_;
    $surface->draw_rect($self->rect, $self->color);
    $surface->draw_gfx_text(
        $self->translate_point(xy => 20, 20),
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

with 'GameFrame::Role::Rectangle';
with 'GameFrame::Role::Event::BoxRouter';

# ------------------------------------------------------------------------------

package GameFrame::eg::TopLevelEventRouter;
use Moose;

with 'GameFrame::Role::Rectangle';
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
    size        => [640, 480],
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






