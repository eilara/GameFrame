#!/usr/bin/perl

use FindBin qw($Bin);
use lib "$Bin/../lib";

# ------------------------------------------------------------------------------

package GameFrame::profile::MockPeriodicTimer;

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

package GameFrame::profile::MockClock;

use Moose;

has now => (is => 'rw', default => 0);

has timer => (is => 'rw');

extends 'GameFrame::Animation::Clock';

sub build_periodic_timer {
    my ($self, $start_time, $timer_sleep, $tick_cb) = @_;
    my $timer = GameFrame::profile::MockPeriodicTimer->new(
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
#    print "now=${\( $self->now )}\n";
    $self->timer->cb->();
}

# ------------------------------------------------------------------------------

package GameFrame::profile::Signal;

use Moose;

sub wait      {}
sub broadcast {}

# ------------------------------------------------------------------------------

package GameFrame::profile::Movable;

use Moose;

with 'GameFrame::Role::Movable';

# ------------------------------------------------------------------------------

package main;
use strict;
use warnings;

my $signal = GameFrame::profile::Signal->new;
my $clock  = GameFrame::profile::MockClock->new(now => 100);
my $iut    = GameFrame::profile::Movable->new(
    xy          => [0, 0],
    speed       => 100,
    motion_args => [
        timeline_args => [
            clock => $clock,
            animation_complete_signal => $signal,
        ],
    ],
);

$iut->move_to([100000, 0]);

my $timer = $clock->timer;
my $i;
while ($timer->is_active) {
    $clock->tick;
    $i++;
}
print "i=$i\n";
