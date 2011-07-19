#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../lib";

# how to use the container to create a scene graph- the composition
# network of game objects
#
# the spawner is the container
# it keeps a strong reference to the children it creates
# it is a DefStack container, which creates children according
# to definitions given in constructor arg 'child_defs'
# when no more definitions remain, no more children are created
#
# the container have 2 responsibilites:
# * creating the children according to some policy
# * keeping the only strong reference to the children in the game
# 
# different container types create their children in different ways:
# * Simple    - whatever is in child_args HashRef is used as constructor
#               arguments for next child created
# * DefStack  - creates children according to a stack of definitions
#               until there are no more definitions
# * DefByName - creates all its children on construction (vs. the
#               other containers creating children on create_next_child())
#               and allows you to name each child, then access the child
#               by name
#
# DefStack is useful when you have a known finite list of enemies
# to spawn
#
# DefByName is useful when you want a static panel with some 
# widgets inside
#
# Simple is flexible enough to use anywhere, just set child_args
# before calling create_next_child()
#
# some containers (e.g. Active) also helps with managing active
# children, and getting notification when they are deactivating

# ------------------------------------------------------------------------------

# just a sprite 

package GameFrame::eg::ContainerSpawnerChild;
use Moose;

with 'GameFrame::Role::Sprite';

# ------------------------------------------------------------------------------

# a spawner which spawns children on click and keeps them forever

package GameFrame::eg::ContainerSpawner;
use Moose;

with qw(
    GameFrame::Role::SDLEventHandler
    GameFrame::Role::Container::DefStack
);

sub on_mouse_button_up { shift->create_next_child }

# ------------------------------------------------------------------------------

package main;
use strict;
use warnings;
use FindBin qw($Bin);
use aliased 'GameFrame::App';

my $app = App->new(
    title    => 'Containers',
    bg_color => 0x0,
);

my %common = (
    child_class => 'GameFrame::eg::ContainerSpawnerChild',
    image       => 'mole',
    size        => [22, 22],
);

# must keep ref to it, for it is not active, and will disappear
# with all its children if we dont
my $container = GameFrame::eg::ContainerSpawner->new(
    child_defs => [
        {%common, xy => [100, 100]},
        {%common, xy => [200, 100]},
        {%common, xy => [100, 200]},
        {%common, xy => [200, 200]},
    ],
);

$app->run;



