#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../lib";

# how to handle SDL events
# click screen to show coordinates

package GameFrame::eg::LastClickPainter;
use Moose;

has last_click => (is => 'rw', default => sub { [0, 0] });

with qw(
    GameFrame::Role::Paintable
    GameFrame::Role::SDLEventHandler
);

sub on_mouse_button_up {
    my ($self, $x, $y) = @_;
    $self->last_click([$x, $y]);
}

sub paint {
    my $self = shift;
    $self->draw_rect(undef, 0x000000FF); # undef means color entire surface
    my $text = join ',', @{ $self->last_click };
    $self->draw_gfx_text([100, 100], 0xFFFFFFFF, $text);
}

# ------------------------------------------------------------------------------

package main;
use strict;
use warnings;
use aliased 'GameFrame::App';

my $app = App->new(
    title => 'Event Handling',
);

my $paintable = GameFrame::eg::LastClickPainter->new;

$app->run;


