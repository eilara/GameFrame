#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../lib";

# same as button demo, only using toolbar class, which saves some typing

# ------------------------------------------------------------------------------

package GameFrame::eg::Button::Controller;
use Moose;

has counter => (
    traits  => ['Counter'],
    is      => 'ro',
    isa     => 'Num',
    default => 0,
    handles => {inc => 'inc', dec => 'dec'},
);

with 'GameFrame::Role::Paintable';

sub quit { exit }

sub paint {
    my ($self, $surface) = @_;
    $surface->draw_gfx_text([300, 150], 0xFFFFFFFF, $self->counter);
}

# ------------------------------------------------------------------------------

package main;
use strict;
use warnings;
use FindBin qw($Bin);
use aliased 'GameFrame::App';
use aliased 'GameFrame::Window';
use aliased 'GameFrame::Widget::Panel';
use aliased 'GameFrame::Widget::Button';
use aliased 'GameFrame::Widget::Toolbar';

my $app = App->new(
    title     => 'Toolbar',
    bg_color  => 0x0,
    resources => "$Bin/resources/eg_toolbar",

    layer_manager_args => [layers => ['foreground']],
);

my $controller = GameFrame::eg::Button::Controller->new
    (layer => 'foreground');

my $button = sub {
    my ($name, $command) = @_;
    return ($name, {
        child_class => 'GameFrame::Widget::Button',
        size        => [45, 44],
        layer       => 'foreground',
        bg_image    => 'button_background',
        icon        => $name,
        target      => $controller,
        command     => $command,
    });
};

my @panel = (
    panel => { # TODO add flex to box panel
        child_class => Panel,
        w           => 640 - 5*1 - 3*45,
        bg_image    => 'toolbar_panel',
    },
);

my $window = Window->new(
    orientation => 'vertical',
    size        => [640, 480],
    child_defs  => [

        top_panel => {
            child_class => Panel,
            h           => 432,
        },

        toolbar => {
            child_class     => Toolbar,
            h               => 48,
            separator_image => 'separator',
            child_defs      => [
                $button->(button_inc => sub { shift->inc }),
                $button->(button_dec => sub { shift->dec }),
                @panel,
                $button->(button_quit => sub { shift->quit }),
            ],
        },
    ],
);

$app->run;

