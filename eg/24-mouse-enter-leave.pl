#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../lib";

# demo of reacting to mouse enter/leave in rectangular event sinks
# panels display their last event, note how mouse enter/leave are
# received

# ------------------------------------------------------------------------------

package GameFrame::eg::EnterLeavePanel;
use Moose;

# depth of panel in tree
has level => (is => 'ro', required => 1);

has last_event => (is => 'rw', default => 'no event');

with 'GameFrame::Role::Rectangle';

with qw(
    GameFrame::Role::Event::BoxRouter
    GameFrame::Role::Paintable
);

after on_mouse_enter => sub { shift->last_event('enter') };
after on_mouse_leave => sub { shift->last_event('leave') };

sub paint {
    my ($self, $surface) = @_;
    my $level = $self->level;
    my $indent = $level * 10;
    my $message = "panel level $level, last event: ". $self->last_event;
    my $xy = $self->translate_point(xy => $indent, $indent);
    $surface->draw_gfx_text($xy, 0xFFFFFFFF, $message);
}

# ------------------------------------------------------------------------------

package main;
use strict;
use warnings;
use FindBin qw($Bin);
use aliased 'GameFrame::App';
use aliased 'GameFrame::Window';

my $app = App->new(
    title    => 'Mouse Enter / Leave',
    bg_color => 0x0,
);

sub panel { {child_class => 'GameFrame::eg::EnterLeavePanel', @_} }

my $window = Window->new(
    orientation => 'vertical',
    size        => [640, 480],
    child_defs  => [
        top_panel    => panel(h => 400, level => 1),
        bottom_panel => panel(h =>  80, level => 1, child_defs => [
            left_panel  => panel(w => 320, level => 2),
            right_panel => panel(w => 100, level => 2),
        ]),
    ],
);

$app->run;






