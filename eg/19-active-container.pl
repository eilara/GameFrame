#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../lib";

# how to clean Active children from Containers after they are deactivated
# and how to get various notifications from the container
# a wave will start, then each time a child is deactivated a notification
# will show, as well as when all children are deactivated

package GameFrame::eg::ActiveContainerChild;
use Moose;

with qw(
    GameFrame::Role::Sprite
    GameFrame::Role::Movable
    GameFrame::Role::Active::Child
);

sub start {
    my $self = shift;
    $self->move_to([0,0]);
}

#sub DEMOLISH { print "DEMOLISH ON $_[0]\n" }

# ------------------------------------------------------------------------------

package GameFrame::eg::ActiveContainerWave;
use Moose;
use Coro::AnyEvent; # for sleep, which is discouraged in anything but examples

has last_message => (is => 'rw', default => 'activating children');

with qw(
    GameFrame::Role::Paintable
    GameFrame::Role::Active
    GameFrame::Role::Container::Simple
    GameFrame::Role::Active::Container
);

sub start {
    my $self = shift;
    for (1..4) {
        Coro::AnyEvent::sleep 1;
        $self->create_next_child; # SPAWN!
    }
}

sub on_child_deactivate {
    my ($self, $child) = @_;
    $self->last_message("deactivated child idx: ". $child->idx);
}

sub on_all_children_deactivated
    { shift->last_message("all children deactivated") }

sub paint {
    my $self = shift;
    $self->draw_gfx_text([400, 100], 0xFFFFFFFF, $self->last_message);
}

# ------------------------------------------------------------------------------

package main;
use strict;
use warnings;
use FindBin qw($Bin);
use aliased 'GameFrame::App';

my $app = App->new(
    title    => 'Active Container',
    bg_color => 0x0,
);

my $wave = GameFrame::eg::ActiveContainerWave->new(
    child_args  => {
        child_class => 'GameFrame::eg::ActiveContainerChild',
        rect        => [600, 400, 22, 22],
        speed       => 300,
        image       => 'mole',
    },
);

$app->run;



