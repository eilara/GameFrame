#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../lib";

# how to move positionable things
# move mouse around to move cursor sprite
# click to start moving sprite moving towards cursor
#
# TODO make it work with constant speed not duration

package GameFrame::eg::MovingFollower;
use Moose;
use aliased 'GameFrame::Role::Animation';

has animation => (is => 'rw', isa => Animation, handles => Animation);

with qw(
    GameFrame::Role::Sprite
    GameFrame::Role::Animated
);

sub follow {
    my ($self, $xy) = @_;

    # TODO animating the same attribute on the same target should stop
    #      current animation automatically so there should be no need for this
    $self->stop_animation if $self->animation;

    # note we use create_move_animation instead of create_animation
    # which is sugar for create_animation on xy
    my $animation = $self->create_move_animation({
        duration  => 1,
        to        => $xy,
        ease      => 'swing',
    });

    # save the animation so we can stop it on next follow()
    $self->animation($animation);

    # start the animation async, on some Coro thread
    $self->start_animation;
}

# ------------------------------------------------------------------------------

package GameFrame::eg::MovingCursor;
use Moose;

has follower => (is => 'ro', required =>1, handles => ['follow']);

with qw(
    GameFrame::Role::Draggable
    GameFrame::Role::Sprite
);

sub on_mouse_button_up {
    my $self = shift;
    $self->follower->follow($self->xy);
}

# hide/show this cursor when entering/leaving app
sub on_app_mouse_focus { shift->is_visible(pop) }

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
    rect  => [100, 100, 22, 26],
    v     => 200,
    image => 'arrow',
    layer => 'middle',
);

my $cursor = GameFrame::eg::MovingCursor->new(
    rect  => [100, 100, 22, 26],
    image    => 'arrow',
    layer    => 'top',
    follower => $follower,
);

$app->run;


