#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../lib";

# how to move positionable things along waypoints
# on running, an arrow should start following the waypoints
#
# note how we hide the cursor after it has reached the last waypoint

package GameFrame::eg::WaypointCrawler;
use Moose;

with qw(
    GameFrame::Role::Active
    GameFrame::Role::Sprite
    GameFrame::Role::FollowsWaypoints
);

sub start {
    my $self = shift;
    $self->follow_waypoints;
    $self->hide;
}

# ------------------------------------------------------------------------------

package main;
use strict;
use warnings;
use FindBin qw($Bin);
use aliased 'GameFrame::App';
use aliased 'GameFrame::Grid::Markers';
use aliased 'GameFrame::Grid::Waypoints';

my $map = <<'WPS';

...A....
G######H
#..#...#
#..BC..#
#...D..#
F###E..I

WPS

my $app = App->new(
    title    => 'Follow Waypoints',
    bg_color => 0x0,

    layer_manager_args => [layers => [qw(path top)]],
);

my $markers = Markers->new(size => $app->size, spacing => 80);

my $waypoints = Waypoints->new(
    markers   => $markers,
    waypoints => $map,
    layer     => 'path',
);

my $crawler = GameFrame::eg::WaypointCrawler->new(
    image      => 'arrow',
    layer      => 'top',
    waypoints  => $waypoints,
    v          => 250,
);

$app->run;



