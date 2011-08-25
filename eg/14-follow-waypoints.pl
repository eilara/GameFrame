#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../lib";

# how to move positionable things along waypoints
# on running, an arrow should start following the waypoints

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

my $markers = Markers->new(size => $app->size, xy => [0,0], spacing => 80);

my $waypoints = Waypoints->new(
    markers   => $markers,
    waypoints => $map,
    layer     => 'path',
);

GameFrame::eg::WaypointCrawler->new(
    size      => [22, 26],
    image     => 'arrow',
    layer     => 'top',
    waypoints => $waypoints,
    speed     => 100,
    centered  => 1,
);

$app->run;



