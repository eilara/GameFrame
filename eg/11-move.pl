#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../lib";

# how to move positionable things
# move mouse around to move cursor sprite
# click to start moving sprite moving towards cursor
# shows how to move a positionable, even when target is moving
# just consume the Movable role and you have "v" property for velocity
# and move() method to move

package GameFrame::eg::MovingFollower;
use Moose;
use GameFrame::Time qw(poll move);

has next_xy => (is => 'rw');

with qw(
    GameFrame::Role::Active
    GameFrame::Role::Sprite
    GameFrame::Role::Movable
);

sub start {
    my $self = shift;
    while (1) {
        poll sleep => 0.1, predicate => sub { $self->next_xy };
        $self->move(
            to   => sub { $self->next_xy(@_) },
            wild => 1,
        );
    }
}

# ------------------------------------------------------------------------------

package GameFrame::eg::MovingCursor;
use Moose;

has follower => (is => 'ro', required =>1);

with qw(
    GameFrame::Role::Draggable
    GameFrame::Role::Sprite
);

sub on_mouse_button_up {
    my $self = shift;
    $self->follower->next_xy($self->xy);
}

# ------------------------------------------------------------------------------

package main;
use strict;
use warnings;
use FindBin qw($Bin);
use aliased 'GameFrame::App';

my $app = App->new(
    title       => 'Moving Positionable',
    bg_color    => 0x0,
    hide_cursor => 1,

    layer_manager_args => [layers => [qw(middle top)]],
);

my $follower = GameFrame::eg::MovingFollower->new(
    xy    => [100, 100],
    v     => 200,
    image => 'arrow',
    layer => 'middle',
);

my $cursor = GameFrame::eg::MovingCursor->new(
    xy       => [100, 100],
    image    => 'arrow',
    layer    => 'top',
    follower => $follower,
);

$app->run;


