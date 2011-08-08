#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../lib";

# same as button demo, only using toolbar class, which saves some typing
# also shows how to disable buttons, in this case when the counter reaches 0
# the minus button is disabled, and enabled again when the counter rises
# above 0
# also shows how to solve the "I need to create lots of background images in
# exact sizes", by using ImageFile, which can be used instead of image file
# name, and scales the image to the size of the container using the Imager
# module, so all you need to create is a 1px panel: the background image of
# the panel is scaled to its size

# ------------------------------------------------------------------------------

package GameFrame::eg::Toolbar::Controller;
use Moose;

has counter => (
    traits  => ['Counter'],
    is      => 'ro',
    isa     => 'Num',
    default => 1,
    handles => {inc => 'inc',dec => 'dec'}, # ???
    trigger => sub { $_[0]->counter_change( $_[0]->counter ) },
);

with 'GameFrame::Role::Paintable';

with 'MooseX::Role::Listenable' => {event => 'counter_change'};

sub quit { exit }

sub paint {
    my $self = shift;
    $self->draw_gfx_text([300, 150], 0xFFFFFFFF, $self->counter);
}

# ------------------------------------------------------------------------------

package GameFrame::eg::Toolbar::Disabler;
use Moose;

has button => (is => 'ro', required => 1, handles => ['is_enabled']);

sub counter_change {
    my ($self, $counter) = @_;
    $self->is_enabled($counter > 0);
}

# ------------------------------------------------------------------------------

package main;
use strict;
use warnings;
use FindBin qw($Bin);
use aliased 'GameFrame::App';
use aliased 'GameFrame::Window';
use aliased 'GameFrame::ImageFile';
use aliased 'GameFrame::Widget::Panel';
use aliased 'GameFrame::Widget::Button';
use aliased 'GameFrame::Widget::Toolbar';

my $app = App->new(
    title     => 'Toolbar',
    bg_color  => 0x0,
    resources => "$Bin/resources/eg_toolbar",
);

my $controller = GameFrame::eg::Toolbar::Controller->new;

my $button = sub {
    my ($name, $command) = @_;
    return ($name, {
        child_class => Button,
        size        => [45, 44],
        bg_image    => 'button_background',
        image       => $name,
        target      => $controller,
        command     => $command,
    });
};

my $next_panel_i;
my $panel = sub {
    return ('panel_'. ++$next_panel_i, {
        child_class => Panel,
        bg_image    => ImageFile->new
            (file => 'toolbar_panel_1x48', stretch => 1),
    });
};

my $window = Window->new(
    orientation => 'vertical',
    rect        => [0, 0, 640, 480],
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
                $panel->(),
                $button->(button_inc => sub { shift->inc }),
                $button->(button_dec => sub { shift->dec }),
                $panel->(),
                $button->(button_quit => sub { shift->quit }),
            ],
        },
    ],
);

my $disabler = GameFrame::eg::Toolbar::Disabler->new
    (button => $window->child('toolbar')->child('button_dec'));
$controller->add_counter_change_listener($disabler);    

$app->run;

