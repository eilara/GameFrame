#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../lib";

# the simplest game object- paintable

package GameFrame::eg::PaintableThing;
use Moose;

with 'GameFrame::Role::Paintable';

sub paint {
    my $self = shift;
    $self->draw_gfx_text([100, 100], 0xFFFFFFFF, 'I can be painted');
}

# ------------------------------------------------------------------------------

package main;
use strict;
use warnings;
use aliased 'GameFrame::App';

my $app = App->new(
    title => 'Paintable',
    size  => [640, 480],
);

# must be created AFTER app
# must keep ref to paintable or it will be destroyed
my $paintable = GameFrame::eg::PaintableThing->new;

$app->run;


