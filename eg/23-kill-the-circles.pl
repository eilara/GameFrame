#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../lib";

# note the use of the Figure role, a paintable positionable thing
# with handy vector drawing methods and an angle at which it points

# ------------------------------------------------------------------------------

package GameFrame::eg::CircleKiller;
use Moose;
use GameFrame::Util::Vectors;

has last_hit_time => (is => 'rw', default => -1);
has radius        => (is => 'ro', default => 25);

with map { "GameFrame::Role::$_" } qw(
    SDLEventHandler
    Active
    Figure
    Movable
    HealthBar
    Scoreable
    Container::Simple
    Active::Container
);

sub start {
    my $self = shift;
    $self->wait_for_death;
    $self->move_to([320, 480]);
    exit;
}

sub paint {
    my $self = shift;
    # spaceship
    $self->draw_polygon_polar(
       0xFFFFFFFF,
       [pi*0, 20], [pi*3/4, 15], [pi*5/4, 15],
   );
   # paint shield, flash red if recently hit, don't if dead
   return unless $self->is_alive;
   my $is_hit = (time - $self->last_hit_time) < 0.1;
   my $color  = $is_hit? 0xFF0000FF: 0x0000FFFF;
   $self->draw_circle($self->xy, $self->radius, $color, 1);
}

# when mouse moves we set our angle
sub on_mouse_motion {
    my ($self, $x, $y) = @_;
    my $angle = angle_between $self->xy_vec, V($x, $y);
    return unless defined $angle; # cursor too close to center
    $self->angle($angle);
}

# fire!
sub on_mouse_button_up {
    my $self = shift;
    # cant fire more than 4 missiles at once
    return if $self->child_count >= 4;

    my $speed    = 300;
    my $dist     = 300; # missile range
    my $angle    = $self->angle;
    my $from     = $self->xy_vec + VP($angle, $self->radius);
    my $to       = $self->xy_vec + VP($angle, $dist); # missle range=300

    $self->create_next_child(
        xy_vec   => $from,
        to       => $to,
        angle    => $angle,
        speed    => $speed,
    );
}

sub on_hit { shift->last_hit_time(time) }

# ------------------------------------------------------------------------------

package GameFrame::eg::CircleKillMissile;
use Moose;
use Math::Trig;
use aliased 'GameFrame::Animation';

with qw(
    GameFrame::Role::Living
    GameFrame::Role::Figure
    GameFrame::Role::Movable
    GameFrame::Role::Active::Child
);

has to     => (is => 'ro', required => 1);
has radius => (is => 'rw', default  => 8);

sub start {
    my $self = shift;
    my $to = $self->to;
    $self->move_to($self->to);

    $self->accept_death if $self->is_alive;

    # death animation
    Animation->new(
        target    => $self,
        attribute => 'radius',
        duration  => $self->radius / 100,
        to        => 1,
    )->start_animation_and_wait;
}

sub collide {
    my $self = shift;
    $self->accept_death;
    $self->stop_motion;
}

sub paint {
    my $self = shift;
    my $r = $self->radius;
    $self->draw_polygon_polar(
       0xFFFFFFFF,
       [pi*0, $r], [pi*3/4, $r - 3], [pi*5/4, $r - 3],
   );
}

# ------------------------------------------------------------------------------

package GameFrame::eg::CircleSpawner;
use Moose;
use List::Util qw(max);
use GameFrame::Util::Vectors;

with qw(
    GameFrame::Role::Container::Simple
    GameFrame::Role::Active
    GameFrame::Role::Spawner
);

sub start {
    my $self = shift;
    # 60 waves in 30 seconds
    $self->spawn(duration => 30, waves => 60);
}

# animate the child up to the edge of the player shield
around next_child_args  => sub {
    my ($orig, $self)   = @_;
    my $player          = V(320, 200);
    my $player_radius   = 25;
    my $idx             = $self->next_child_idx;
    my $circle_radius   = max(16, 120 - $idx * 2);
    my $duration        = max(0.7, 4 - $idx * 0.067);
    my $from            = random_edge_vector(V(880,720)) - V(120,120);
    my $to              = $player + normalize_vector($from - $player) *
                          ($player_radius + $circle_radius);
    return {
        %{$self->$orig},
        xy_vec         => $from,
        radius         => $circle_radius,
        animation_args => [
            attribute => 'xy_vec',
            to        => $to,
            duration  => $duration,
            ease      => 'swing',
        ],
    };
};

# ------------------------------------------------------------------------------

package GameFrame::eg::EvilCircle;
use Moose;
use MooseX::Types::Moose qw(Int);
use GameFrame::MooseX;
use aliased 'GameFrame::Animation';
 
has player => (is => 'ro', required => 1, weak_ref => 1);
has radius => (is => 'rw', isa => Int, required => 1);

with qw(
    GameFrame::Role::Paintable
    GameFrame::Role::Positionable
    GameFrame::Role::Living
    GameFrame::Role::Active::Child
);

compose_from Animation,
    inject => sub { (target => shift) },
    has    => {handles => [qw(
        start_animation_and_wait
        stop_animation
    )]};

sub start {
    my $self = shift;
    $self->start_animation_and_wait;
    # we are alive if we got to player without dying
    # we are dead if we got hit by a missile    
    if ($self->is_alive) {
        $self->player->hit(10);
        return;
    }
    # death animation
    Animation->new(
        target    => $self,
        attribute => 'radius',
        duration  => $self->radius / 100,
        to        => 1,
    )->start_animation_and_wait;
}

sub collide {
    my $self = shift;
    $self->accept_death;
    $self->stop_animation;
}

sub paint {
    my $self = shift;
    $self->draw_circle($self->xy, $self->radius, 0xFFFFFFFF, 1);
}

# ------------------------------------------------------------------------------

package GameFrame::eg::CircleMissileCollisionDetector;
use Moose;
use Coro::AnyEvent; # for sleep
use aliased 'GameFrame::Animation';

has [qw(spawner player)] => (is => 'ro', required => 1);

with 'GameFrame::Role::Active';

sub start {
    my $self = shift;
    while (1) {
        Coro::AnyEvent::sleep 1/60;
        my @collisions = $self->detect_collisions;
        for my $collision (@collisions) {
            my ($missile, $circle) = @$collision;
            $_->collide for $missile, $circle;
            $self->player->add_to_score(1);
        }
    }
}

sub detect_collisions {
    my $self = shift;
    my @collisions = map { $self->detect_collision($_) }
                     map { my $missile = $_;
                          map { [$missile, $_] }
                          grep { $_->is_alive }
                          $self->spawner->all_children;
                     }
                     grep { $_->is_alive }
                     $self->player->all_children;
    return @collisions;
}

sub detect_collision {
    my ($self, $objects) = @_;
    my ($missile, $circle) = @$objects;
    my $dist = ($missile->xy_vec - $circle->xy_vec)->abs -
               $missile->radius - $circle->radius;
    return $dist <= 1? $objects: ();
}

# ------------------------------------------------------------------------------

package main;
use strict;
use warnings;
use aliased 'GameFrame::App';

my $app = App->new(
    title    => 'Kill the Circles',
    bg_color => 0x0,
);

# the player is the circle killer, its children are missiles
my $player = GameFrame::eg::CircleKiller->new(
    xy                => [320, 200],
    start_hp          => 50,
    health_bar        => [-13, -25, 22, 2],
    speed             => 100, # speed when dropping to death
    child_args        => {
        child_class => 'GameFrame::eg::CircleKillMissile',
        start_hp    => 1,
    },
);

# spawns evil circles
my $spawner = GameFrame::eg::CircleSpawner->new(
    child_args  => {
        child_class => 'GameFrame::eg::EvilCircle',
        player      => $player,
        start_hp    => 1,
    },
);

# detects collisions
my $detector = GameFrame::eg::CircleMissileCollisionDetector->new(
    player  => $player,
    spawner => $spawner,
);

$app->run;

__END__


