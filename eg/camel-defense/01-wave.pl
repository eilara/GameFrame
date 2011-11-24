#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../../lib";

package GameFrame::eg::CamelDefense::SpeedController;
use Moose;

has speed   => (is => 'rw', default => 100);
has spawner => (is => 'ro');

with qw(
    GameFrame::Role::SDLEventHandler
    GameFrame::Role::Paintable
);

sub on_left_mouse_button_up {
    my $self = shift;
    $self->change_speed(20);
}

sub on_right_mouse_button_up {
    my $self = shift;
    $self->change_speed(-20);
}

sub change_speed {
    my ($self, $change) = @_;    
    my $speed = $self->speed + $change;
    $speed = $speed < 0.01? 0.01: $speed;
    $self->speed($speed);
    $self->spawner->child_args->{speed} = $speed;
    $_->speed($speed) for $self->spawner->all_children;
}

sub paint {
    my $self = shift;
    $self->draw_gfx_text([20, 460], 0xFFFF00FF, 'left mouse button haste, right slow');
}

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

my $controller = GameFrame::eg::CamelDefense::SpeedController->new(
    layer   => 'creeps',
    spawner => $wave,
);

$app->run;


__END__

