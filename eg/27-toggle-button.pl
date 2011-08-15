#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../lib";

# TODO NOT DONE YET
#
# demo of toggle buttons, also of using the wrong control scheme for a game ;)
# be careful of the incoming circles- move left and right with the toggle buttons
# untoggle to stop moving

# ------------------------------------------------------------------------------

package GameFrame::eg::ToggleButton::Player;
use Moose;
use Math::Trig;
use Time::HiRes qw(time);
use Moose::Util::TypeConstraints;

# -1 left, 0 no dir, 1 right
has dir => (is => 'rw', default => 0, trigger => sub { shift->dir_trigger });

has radius => (is => 'ro', required => 1);

has [qw(left_edge right_edge)] => (is => 'ro', required => 1);

with 'MooseX::Role::Listenable' => {event => 'dir_change'};
with 'MooseX::Role::Listenable' => {event => 'pause_request'};

with map { "GameFrame::Role::$_" }
       qw( SDLEventHandler Figure Movable HealthBar Scoreable );

sub pause { shift->pause_request(pop) }

sub quit { exit }

# called on Movable when reached field edge
after destination_reached => sub { shift->dir(0) };

sub left {
   my ($self, $start_or_stop) = @_;
   $self->dir($start_or_stop? -1: 0); 
}

sub right {
   my ($self, $start_or_stop) = @_;
   $self->dir($start_or_stop? 1: 0); 
}

# when dir changes, notify toggle buttons and update motion
sub dir_trigger {
    my $self = shift;
    my $dir = $self->dir;
    $self->stop_motion;
    $self->dir_change($dir);
    return if $dir == 0;

    my $to = $dir == -1? 'left_edge': 'right_edge';
    $self->set_to( $self->$to );
    $self->start_motion;
}

# collide with circle
sub collide {
    my $self = shift;
    $self->hit(10);
}

sub on_death { exit }

sub paint {
    my $self = shift;
    # spaceship
    $self->draw_polygon_polar(
       0xFFFFFFFF,
       [pi*0, 20], [pi*3/4, 15], [pi*5/4, 15],
   );
   # paint shield, flash red if recently hit, don't if dead
   return unless $self->is_alive;
   my $color  = $self->has_been_recently_hit? 0xFF0000FF: 0x0000FFFF;
   $self->draw_circle($self->xy, 25, $color, 1);
}

# ------------------------------------------------------------------------------

package GameFrame::eg::ToggleButton::Spawner;
use Moose;
use List::Util qw(max min);

with qw(
    GameFrame::Role::Container::Simple
    GameFrame::Role::Active
    GameFrame::Role::Spawner
);

sub start {
    my $self = shift;
    $self->spawn(duration => 30, waves => 60);
}

around next_child_args => sub {
    my ($orig, $self)  = @_;
    my $idx            = $self->next_child_idx;
    my $r              = min(80, 8 + 1.3 * $idx);
    my $x              = (int rand (640 - 2 * $r)) + $r;
    my $duration       = max(1, 4 - $idx * 0.047);
    return {
        %{$self->$orig},
        xy             => [$x, -2 * $r],
        radius         => $r,
        animation_args => [
            attribute  => 'xy_vec',
            to         => [$x, 480 + 2 * $r],
            duration   => $duration,
            ease       => 'swing',
        ],
    };
};

# ------------------------------------------------------------------------------

package GameFrame::eg::ToggleButton::EvilCircle;
use Moose;
use GameFrame::MooseX;
use aliased 'GameFrame::Animation';

has radius => (is => 'rw', required => 1);
has player => (is => 'ro', required => 1, weak_ref => 1);

with qw(
    GameFrame::Role::Paintable
    GameFrame::Role::Positionable
    GameFrame::Role::Living
    GameFrame::Role::Active::Child
);

compose_from Animation,
    inject => sub { (target => shift) },
    has    => {handles => [qw(start_animation_and_wait stop_animation
                              pause_animation resume_animation)]};

sub start {
    my $self = shift;
    $self->start_animation_and_wait;
    if ($self->is_alive) {
        $self->accept_death;
        $self->player->add_to_score(1);
        return;
    }
    Animation->new(
        target    => $self,
        attribute => 'radius',
        duration  => $self->radius / 100,
        to        => 1,
    )->start_animation_and_wait;
}

# collide with player
sub collide {
    my $self = shift;
    $self->accept_death;
    $self->stop_animation;
}

sub paint {
    my $self = shift;
    $self->draw_circle_filled($self->xy, $self->radius, 0xFFFFFFFF, 1);
}

# ------------------------------------------------------------------------------

package GameFrame::eg::ToggleButton::Controller;
use Moose;

has [qw(toolbar spawner player)] => (is => 'ro', required => 1, weak_ref => 1);

sub dir_change {
    my ($self, $dir) = @_;
    $self->toolbar->child('button_right')->toggle_off if $dir == 0 or $dir == -1;
    $self->toolbar->child('button_left' )->toggle_off if $dir == 0 or $dir ==  1;
}

sub pause_request {
    my ($self, $is_pause) = @_;

    my $enable_disable = $is_pause? 'disable': 'enable';
    $self->toolbar->child($_)->$enable_disable for qw(button_left button_right);

    my $pause_resume = ($is_pause? 'pause': 'resume'). '_animation';
    $self->player->motion->$pause_resume;
    $_->$pause_resume for $self->spawner->all_children;
    $self->spawner->$pause_resume;
}

# ------------------------------------------------------------------------------

package main;
use strict;
use warnings;
use Math::Trig;
use FindBin qw($Bin);
use aliased 'GameFrame::App';
use aliased 'GameFrame::ImageFile';
use aliased 'GameFrame::Window';
use aliased 'GameFrame::Widget::Panel';
use aliased 'GameFrame::Widget::Button';
use aliased 'GameFrame::Widget::Button::Toggle';
use aliased 'GameFrame::Widget::Toolbar';
use aliased 'GameFrame::CollisionDetector';

my $app = App->new(
    title     => 'Toggle Button',
    bg_color  => 0x0,
    resources => "$Bin/resources/eg_toolbar",

    layer_manager_args => [layers => [qw(enemy toolbar player)]],
);

my $player = GameFrame::eg::ToggleButton::Player->new(
    xy         => [275, 405],
    health_bar => [-13,  18, 25, 2],
    speed      => 200,
    layer      => 'player',
    angle      => pi*6/4,
    start_hp   => 50,
    radius     => 25, # shield radius
    left_edge  => [  0 + 25, 405],
    right_edge => [640 - 25, 405],
);

my $spawner = GameFrame::eg::ToggleButton::Spawner->new(
    child_args => {
        child_class => 'GameFrame::eg::ToggleButton::EvilCircle',
        player      => $player,
        layer       => 'enemy',
        start_hp    => 1,
    },
);

my $button = sub {
    my ($name, $is_toggle) = @_;
    return ("button_$name", {
        child_class    => ($is_toggle? Toggle: Button),
        layer          => 'toolbar',
        size           => [45, 44],
        bg_image       => 'button_background',
        image          => "button_$name",
        target         => $player,
        command        => sub { $_[0]->$name($_[1]) },
    });
};

# sub used to make toolbar background panels
my $next_panel_i;
my $panel = sub {
    return ('panel_'. ++$next_panel_i, {
        child_class => Panel,
        layer       => 'toolbar',
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
            layer           => 'toolbar',
            child_defs      => [
                $panel->(),
                $button->(left  => 1),
                $button->(right => 1),
                $panel->(),
                $button->(pause => 1),
                $button->('quit'),
            ],
        },
    ],
);

# keep the buttons in sync- when one is hit the other should be untoggled
# and both need to be untoggled when we reach the edge
my $controller = GameFrame::eg::ToggleButton::Controller->new(
    toolbar => $window->child('toolbar'),
    spawner => $spawner,
    player  => $player,
);
$player->add_dir_change_listener($controller);    
$player->add_pause_request_listener($controller);    

# detects collisions
my $detector = CollisionDetector->new(
    container_1 => $spawner,
    child_2     => $player,
);

$app->run;

__END__
