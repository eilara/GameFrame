#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../../lib";

# ------------------------------------------------------------------------------

use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../../lib";
use aliased 'GameFrame::App';
use aliased 'GameFrame::Grid::Markers';
use aliased 'GameFrame::Grid::Waypoints';
use aliased 'GameFrame::CamelDefense::Creep';
use aliased 'GameFrame::CamelDefense::Wave';

my $app = App->new(
    title     => 'Grid',
    bg_color  => 0x0,
    resources => "$Bin/resources",

    layer_manager_args => [layers => [qw(path creeps)]],
);

my $markers = Markers->new(
    xy      => [0, 0],
    size    => $app->size,
    spacing => 32,
);

my $waypoints = Waypoints->new(
    markers  => $markers,
    map_file => "$Bin/waypoints-1.map",
    layer    => 'path',
);

my $wave = Wave->new(
    duration   => 10,
    waves      => 50,
    child_args => {
        child_class => Creep,
        size        => [21, 21],
        image       => 'creep_normal',
        layer       => 'creeps',
        waypoints   => $waypoints,
        speed       => 100,
        start_hp    => 100,
        centered    => 1,
        health_bar  => [-11, -18, 22, 2],
        sequence    => 'alive',
        sequences   => {
            alive      => [[0, 1]],
            death      => [map { [    $_, 0] } 0..6],
            enter_grid => [map { [6 - $_, 1] } 0..6],
            leave_grid => [map { [    $_, 1] } 0..6],
        },
    },
);



$app->run;


__END__

