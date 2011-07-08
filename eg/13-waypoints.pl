#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../lib";

# waypoints - draw a path through a map

package main;
use strict;
use warnings;
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
    title => 'Waypoints',

    layer_manager_args => [layers => [qw(path)]],
);

my $markers = Markers->new(size => $app->size, xy => [0,0], spacing => 80);

my $waypoints = Waypoints->new(
    markers   => $markers,
    waypoints => $map,
    layer     => 'path',
);

$app->run;



