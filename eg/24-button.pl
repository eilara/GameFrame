#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../lib";

# demo of how to create buttons that can be clicked and placed
# on a toolbar
# click buttons to see number go up/down
#
# note the use of the optional bg_image on a panel

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
use aliased 'GameFrame::Widget::Image';
use aliased 'GameFrame::Widget::Button';

my $app = App->new(
    title     => 'Toolbar',
    bg_color  => 0x0,
    resources => "$Bin/resources/eg_toolbar",

    layer_manager_args => [layers => ['foreground']],
);

my $controller = GameFrame::eg::Button::Controller->new
    (layer => 'foreground');

my $sep_idx;    
my $sep = sub { 
   return ("_border_". ++$sep_idx, {
        child_class => Image,
        w           => 1,
        image       => 'separator',
    });
};

my $button = sub {
    my ($name, $command) = @_;
    return ($name, {
        child_class => Button,
        size        => [45, 44],
        layer       => 'foreground',
        bg_image    => 'button_background',
        icon        => $name,
        target      => $controller,
        command     => $command,
    });
};

my $window = Window->new(
    orientation => 'vertical',
    size        => [640, 480],
    child_defs  => [

        top_panel => {
            child_class => Panel,
            h           => 432, # w is implied by parent width
        },

        toolbar => {
            child_class => Panel,
            orientation => 'horizontal',
            h           => 48,
            child_defs  => [
                $sep->(),
                $button->(button_inc => sub { shift->inc }),

                $sep->(),
                $button->(button_dec => sub { shift->dec }),

                $sep->(),
                panel => {
                    child_class => Panel,
                    orientation => 'horizontal',
                    w           => 640 - 5*1 - 3*45,
                    bg_image    => 'toolbar_panel',
                },

                $sep->(),
                $button->(button_quit => sub { shift->quit }),

                $sep->(),

            ],
        },
    ],
);

$app->run;






