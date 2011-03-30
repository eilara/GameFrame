#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../lib";

# how to configure games in a descriptor file using the GameFromFile role
# exactly like the waypoint follower example, except all the properties
# of all the objects (except the DescriptorWaypointCrawler) are defined
# in an external configuration file called waypoints.gf
#
# also shows how to compose objects using GameFrame::MooseX::compose_from

package GameFrame::eg::DescriptorWaypointCrawler;
use Moose;

with qw(
    GameFrame::Role::Active
    GameFrame::Role::Sprite
    GameFrame::Role::FollowsWaypoints
);

sub start {
    my $self = shift;
    $self->show;
    $self->follow_waypoints;
    $self->hide;
}

# ------------------------------------------------------------------------------

package GameFrame::eg::DescriptorExample;
use Moose;
use GameFrame::MooseX;
use aliased 'GameFrame::App';
use aliased 'GameFrame::Grid::Markers';
use aliased 'GameFrame::Grid::Waypoints';

compose_from App      , has    => {handles => ['size']};
compose_from Markers  , inject => [qw(size)];
compose_from Waypoints, inject => [qw(markers)];

compose_from 'GameFrame::eg::DescriptorWaypointCrawler',
    prefix => 'crawler',
    inject => ['waypoints'];

with 'GameFrame::Role::GameFromFile';

sub BUILD { shift->crawler } # hack to eagerize crawler construction

# ------------------------------------------------------------------------------

package main;
use strict;
use warnings;
use FindBin qw($Bin);

GameFrame::eg::DescriptorExample->run("$Bin/waypoints.gf");

