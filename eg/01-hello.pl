#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../lib";

# the simplest app- a black window with a title

use strict;
use warnings;
use GameFrame::App;

GameFrame::App->new(
    title => 'Hello World',
    size  => [640, 480],
)->run;

