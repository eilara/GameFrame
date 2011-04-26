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
use List::Util qw(max);
use Math::Vector::Real;
use GameFrame::Util qw(is_in_rect);

# for benefit of health bar
sub w { 25 }

has field_size => (is => 'ro', required => 1);

has last_hit_time => (is => 'rw', default => -1);

has velocity => (is => 'rw', default => sub { V(0, 0) },
          trigger => sub { shift->velocity_trigger });

has wakeup_signal => (is => 'ro', default => sub { Signal->new });

with 'GameFrame::Role::Point';

with qw(
    GameFrame::Role::SDLEventHandler
    GameFrame::Role::Figure
    GameFrame::Role::HealthBar
    GameFrame::Role::Scoreable
    GameFrame::Role::Active
);

# ship faces up
has '+angle' => (default => pi*6/4);

with 'MooseX::Role::Listenable' => {event => 'velocity_change'};

sub start {
    my $self = shift;

    my $shield = 25; # px shield size
    # field rectangle defined so shield does not leave field
    my $field  = [
        $shield, 0,
        $self->field_size->[0] - 2 * $shield, $self->field_size->[1],
    ];

    # given this next position, is it ok to move to it? when false, halt movement        
    my $constraint_cb = sub { is_in_rect @{ pop() }, @$field };

    my $signal = $self->wakeup_signal;

    $self->move(
        signal => $self->wakeup_signal,
        limit  => $constraint_cb,
        until  => sub { 1 },
    );
}

sub move {
    my ($self, %args) = @_;
    my ($signal, $limit, $until) = @args{qw<signal limit until>};
    my $sleep = 1/60;

    while ($until->()) {

        my $timer;
        # repeated EV timer does movement and runs as long as constraint_cb
        # is true for next position, or until canceled because of wake up signal
        $timer = EV::timer 0, $sleep, sub {

            my $new_pos = V(@{ $self->xy }) + $sleep * $self->velocity;
            if ($limit->($self, $new_pos)) {
                $self->xy([@$new_pos]);
            } else {
                $signal->send;
            }

        } unless $self->velocity == V(0, 0);

        $signal->wait;
        undef $timer;
    }
}

# called from event handling coro
sub velocity_trigger {
    my $self = shift;
    $self->velocity_change($self->velocity);
    $self->wakeup_signal->send;
}

# toggle buttons send the toggle state as a param
sub left  { shift->velocity( V(pop()? -250: 0, 0) ) }
sub right { shift->velocity( V(pop()?  250: 0, 0) ) }
sub quit  { exit }

sub on_hit { shift->last_hit_time(time) }

sub on_death {
    my $self = shift;
    print "DEAD\n";
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

# ------------------------------------------------------------------------------

package GameFrame::eg::ToggleButton::Controller;
use Moose;

has toolbar => (is => 'ro', required => 1, handles => ['child']);

sub velocity_change {
    my ($self, $v) = @_;
    my $dir = $v->[0];
    return if $dir == 0;
    $self->child(
        'button_'.
        ($dir < 0? 'right': 'left')
    )->toggle_off;
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

# keep the buttons in sync- when one is hit the other should be untoggled
my $controller = GameFrame::eg::ToggleButton::Controller->new
    (toolbar => $window->child('toolbar'));
$player->add_velocity_change_listener($controller);    

$app->run;

