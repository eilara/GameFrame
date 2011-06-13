#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../lib";

# how to use the container roles for 1 -> * strong composition between
# game objects
# click mouse to start a wave of cursors
#
# the wave and the wave manager are composites with a 1 -> * relationship
# with their children
# both create and add children using $self->create_next_child
# the wave is a simple container, that creates the child according to the
# current definition in child_args property
# the wave manager is a DefStack container, and keeps the child definitons
# in a child_def property, which is shifted on each create_next_child()
# when there are no more defs, it turns into a nop

package GameFrame::eg::CursorWaveChild;
use Moose;

with qw(
    GameFrame::Role::Sprite
    GameFrame::Role::Movable
    GameFrame::Role::Active
);

sub start {
    my $self = shift;
    $self->move(to => sub { [0, 0] });
    $self->hide;
}

# ------------------------------------------------------------------------------

package GameFrame::eg::CursorWave;
use Moose;
use GameFrame::Time qw(interval);

with qw(
    GameFrame::Role::Active
    GameFrame::Role::Container::Simple
);

has [qw(num_in_wave wave_interval)] => (is => 'ro', required => 1);

sub start {
    my $self = shift;
    interval
        times => $self->num_in_wave,
        sleep => $self->wave_interval,
        step  => sub { $self->create_next_child };
}

# ------------------------------------------------------------------------------

package GameFrame::eg::CursorWaveManager;
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

my %common_wave  = (child_class => 'GameFrame::eg::CursorWave');
my %common_child = (
    child_class => 'GameFrame::eg::CursorWaveChild',
    xy          => [600, 400],
    image       => 'arrow',
); 

my $spawn_manager = GameFrame::eg::CursorWaveManager->new(
    child_defs => [
        {
            %common_wave, num_in_wave => 10, wave_interval => 1,
            child_args => {%common_child, v => 200},
        },
        {
            %common_wave, num_in_wave => 20, wave_interval => 0.5,
            child_args => {%common_child, v => 100},
        },
        {
            %common_wave, num_in_wave =>  5, wave_interval => 2,
            child_args => {%common_child, v => 300},
        },
    ],
);

$app->run;



