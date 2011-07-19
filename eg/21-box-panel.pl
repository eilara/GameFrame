#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../lib";

# how to use the box panel role to layout child rectangles
# the box panel role saves you from doing layout by serving
# as a box layout manager for its children

package GameFrame::eg::BoxPanelChild;
use Moose;

has color => (is => 'ro', required => 1);

with qw(
    GameFrame::Role::Paintable
    GameFrame::Role::Rectangular
);

sub paint {
    my $self = shift;
    $self->draw_rect($self->rect, $self->color);
}

# ------------------------------------------------------------------------------

package GameFrame::eg::BoxPanelContainer;
use Moose;

with qw(
    GameFrame::Role::Rectangular
    GameFrame::Role::Panel::Box
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

my $panel = GameFrame::eg::BoxPanelContainer->new(
    orientation => 'vertical',
    rect        => [0, 0, 640, 480],
    child_defs  => [

        top_panel => {
            child_class => 'GameFrame::eg::BoxPanelChild',
            h           => 400, # w is implied by parent width
            color       => 0xFF0000FF,
        },

        bottom_panel => {
            child_class => 'GameFrame::eg::BoxPanelContainer',
            h           => 80,
            orientation => 'horizontal',
            child_defs  => [

                left_panel => {
                    child_class => 'GameFrame::eg::BoxPanelChild',
                    w           => 400, # h is implied by parent height
                    color       => 0x00FF00FF,
                },

                right_panel => {
                    child_class => 'GameFrame::eg::BoxPanelChild',
                    w           => 240,
                    color       => 0x0000FFFF,
                },
            ],
        },
    ],
);

$app->run;




__END__


