#!/usr/bin/perl
use lib '../lib';

# the grid shows the markers and the waypoints

package main;
use strict;
use warnings;
use aliased 'GameFrame::App';
use aliased 'CamelDefense::World::Grid';

my $app = App->new(
    title    => 'Markers',
    size     => [640, 480],
    bg_color => 0x6F6F6FFF,
    layer_manager_args => [layers => [qw(markers path)]],
);

my $map = <<'WPS';

...A....
...#....
...#....
...BC...
....D...
....E...

WPS

my $grid = Grid->new(
    markers_args => [
        size    => $app->size,
        spacing => 80,
        layer   => 'markers',
    ],

    waypoints_args => [
        waypoints => $map,
        layer     => 'path',
    ],
);

$app->run;


