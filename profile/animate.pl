#!/usr/bin/perl

use FindBin qw($Bin);
use lib "$Bin/../lib";

# ------------------------------------------------------------------------------

package GameFrame::profile_animation::MockPeriodicTimer;

use Moose;

has [qw(is_active start_time timer_sleep cb)] => (is => 'rw', default => 0);
has counter => (is => 'rw', default => 1);

sub start { shift->is_active(1) }
sub stop  { shift->is_active(0) }

sub set {
    my ($self, $start, $sleep) = @_;
    $self->start_time($start);
    $self->timer_sleep($sleep);
}

sub tick {
    my $self = shift;
    my $counter = $self->counter;
    $self->counter($counter + 1);
    my $now = $counter * $self->timer_sleep;
    return $now;
}

# ------------------------------------------------------------------------------

package GameFrame::profile_animation::MockClock;

use Moose;

has now => (is => 'rw', default => 0);

has timer => (is => 'rw');

extends 'GameFrame::Animation::Clock';

sub build_periodic_timer {
    my ($self, $start_time, $timer_sleep, $tick_cb) = @_;
    my $timer = GameFrame::profile_animation::MockPeriodicTimer->new(
        cb          => $tick_cb,
        start_time  => $start_time,
        timer_sleep => $timer_sleep,
    );
    $self->timer($timer);
    return $timer;
}

sub tick {
    my $self = shift;
    my $now = $self->timer->tick;
    $self->now(100 + $now);
#print "now=${\( $self->now )}\n";
    $self->timer->cb->();
}

# ------------------------------------------------------------------------------

package GameFrame::profile_animation::Signal;

use Moose;

sub wait      {}
sub broadcast {}

# ------------------------------------------------------------------------------

package GameFrame::profile_animation::Animated;

use Moose;

with qw(
    GameFrame::Role::Animated
    GameFrame::Role::Sprite
);

# ------------------------------------------------------------------------------

package main;
use strict;
use warnings;
use FindBin qw($Bin);
use GameFrame::ResourceManager;
use GameFrame::Role::Paintable;
use GameFrame::Util::Vectors;
use aliased 'GameFrame::App::LayerManager';

GameFrame::ResourceManager::Set_Path("$Bin/../eg/resources");
GameFrame::Role::Paintable::Set_Layer_Manager(LayerManager->new);
my $signal = GameFrame::profile_animation::Signal->new;
my $clock  = GameFrame::profile_animation::MockClock->new(now => 100);
my $iut    = GameFrame::profile_animation::Animated->new(
    rect        => [0, 0, 22, 26],
    image       => 'arrow',
);

my $ani = $iut->create_animation({
    attribute => 'xy',
    speed     => 100,
    to        => V(1000000, 0),
    timeline_args => [
        clock => $clock,
        animation_complete_signal => $signal,
    ],
});

$ani->start_animation;
my $timer = $clock->timer;
my $i;
while ($timer->is_active) {
    $clock->tick;
    $i++;
}
print "i=$i\n";
