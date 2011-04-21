#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../lib";

# TODO NOT DONE YET
#
# demo of toggle buttons, also of using the wrong control scheme for a game ;)
# be careful of the incoming lines- move left and right with the toggle buttons
# untoggle to stop moving

# ------------------------------------------------------------------------------

package GameFrame::eg::ToggleButton::Player;
use Moose;
use Coro;
use Coro::EV;
use EV;
use aliased 'Coro::Signal';
use Math::Trig;
use Time::HiRes qw(time);

# for benefit of health bar
sub w { 25 }

has field_size => (is => 'ro', required => 1);

has last_hit_time => (is => 'rw', default => -1);

has direction => (is => 'rw', default =>  0, # 0=freeze, -1=left, 1=right
                  trigger => sub { shift->direction_trigger });

has direction_change_signal => (is => 'ro', default => sub { Signal->new });

has move_wake_signal => (is => 'rw');

with 'GameFrame::Role::Point';

with qw(
    GameFrame::Role::SDLEventHandler
    GameFrame::Role::Figure
    GameFrame::Role::HealthBar
    GameFrame::Role::Scoreable
    GameFrame::Role::Movable
    GameFrame::Role::Active
);

# ship faces up
has '+angle' => (default => pi*6/4);

with 'MooseX::Role::Listenable' => {event => 'dir_change'};

sub start {
    my $self           = shift;
    my $sleep          = 1/60;
    my $should_wait    = 1;
    my $completed_move = 0;
    my $shield_radius  = 25;
    my $max_x          = $self->field_size->[0];
    my $dir            = sub { $self->direction };
    my $in_field       = sub { 
        ($dir->() == -1 and $self->x > $shield_radius) ||
        ($dir->() ==  1 and ($self->x < $max_x - $shield_radius))
    };

    while (1) { # TODO while alive
        $self->direction_change_signal->wait if $should_wait;           
        if ($dir->()) {
            $self->move_wake_signal(my $signal = Signal->new);
            my $timer = EV::timer 0, $sleep, sub {
                if ($in_field->()) {
                    $self->self_translate_point(x => 2*$dir->());
                } else {
                    $completed_move = 1;
                    $signal->send;
                }
            };
            $signal->wait;
            undef $timer;
            $should_wait = $completed_move || ($dir->()? 0: 1);
            $self->move_wake_signal(undef);
            $completed_move = 0;
        }
    }
}

# called from event handling coro
sub direction_trigger {
    my $self = shift;
    my $d = $self->direction;
    $self->dir_change($d);
    # if we are moving stop timer, else just send signal
    if ($self->move_wake_signal) {
        $self->move_wake_signal->send;
    } else {
        $self->direction_change_signal->send;
    }
}

sub paint {
    my ($self, $surface) = @_;
    # spaceship
    $self->draw_polygon(
       $surface, 0xFFFFFFFF,
       [pi*0, 20], [pi*3/4, 15], [pi*5/4, 15],
   );
   # paint shield, flash red if recently hit, don't if dead
   return unless $self->is_alive;
   my $is_hit = (time - $self->last_hit_time) < 0.1;
   my $color  = $is_hit? 0xFF0000FF: 0x0000FFFF;
   $surface->draw_circle($self->xy, 25, $color, 1);
}

# toggle buttons send the toggle state as a param
sub left  { shift->direction(pop()? -1: 0) }
sub right { shift->direction(pop()?  1: 0) }

sub quit { exit }

sub on_hit { shift->last_hit_time(time) }

sub on_death {
    my $self = shift;
    async {
        $self->move(to => sub { [320, 480] });
        exit;
    };
}

# ------------------------------------------------------------------------------

package GameFrame::eg::ToggleButton::Controller;
use Moose;

has toolbar => (is => 'ro', required => 1, handles => ['child']);

sub dir_change {
    my ($self, $direction) = @_;
    $self->child('button_'. ($direction == -1? 'right': 'left'))->toggle_off;
}

# ------------------------------------------------------------------------------

package main;
use strict;
use warnings;
use FindBin qw($Bin);
use aliased 'GameFrame::App';
use aliased 'GameFrame::ImageFile';
use aliased 'GameFrame::Window';
use aliased 'GameFrame::Widget::Panel';
use aliased 'GameFrame::Widget::Button';
use aliased 'GameFrame::Widget::Button::Toggle';
use aliased 'GameFrame::Widget::Toolbar';

my $app = App->new(
    title     => 'Toggle Button',
    bg_color  => 0x0,
    resources => "$Bin/resources/eg_toolbar",

    layer_manager_args => [layers => ['foreground']],
);

my $player = GameFrame::eg::ToggleButton::Player->new(
    field_size        => [640, 432],
    xy                => [320, 405],
    start_hp          => 50,
    health_bar_offset => [-13, 18],
    v                 => 100,
);

my $button = sub {
    my ($name, $command, $is_toggle) = @_;
    return ($name, {
        child_class => ($is_toggle? Toggle: Button),
        size        => [45, 44],
        layer       => 'foreground',
        bg_image    => 'button_background',
        icon        => $name,
        target      => $player,
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
                $panel->(),
                $button->(button_left  => sub { $_[0]-> left($_[1]) }, 1),
                $button->(button_right => sub { $_[0]->right($_[1]) }, 1),
                $panel->(),
                $button->(button_quit  => sub { shift->quit  }),
            ],
        },
    ],
);

my $controller = GameFrame::eg::ToggleButton::Controller->new
    (toolbar => $window->child('toolbar'));
$player->add_dir_change_listener($controller);    

$app->run;

