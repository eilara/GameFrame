#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../lib";

# a simple paintable- grid markers

package main;
use strict;
use warnings;
use aliased 'GameFrame::App';
use aliased 'GameFrame::Grid::Markers';

my $app = App->new(
    title => 'Markers',
);

my $markers = Markers->new(size => $app->size, xy => [0, 0], spacing => 32);

$app->run;


