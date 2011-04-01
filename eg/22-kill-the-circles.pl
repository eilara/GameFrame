#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../lib";

# note the use of the Figure role, a paintable positionable thing
# with handy vector drawing methods and an angle at which it points

# ------------------------------------------------------------------------------

package GameFrame::eg::CircleMissileCollisionDetector;
use Moose;
use Coro;
use List::Util qw(first);
use GameFrame::Time qw(poll rest);

has [qw(spawner player)] => (is => 'ro', required => 1, weak_ref => 1);

with 'GameFrame::Role::Active';

sub start {
    my $self = shift;
    while (1) {
        my $collisions = poll
            sleep     => 0.05,
            predicate => sub { $self->detect_collisions };
        for my $collision (@$collisions) {
            my ($missile, $circle) = @$collision;
            $_->deactivate for $missile, $circle;
            $self->player->add_to_score(1);
            async {
                $_->color(0xFF0000FF) for $circle, $missile;
                rest 0.1;
                $self->spawner->remove_child($circle);
                $self->player->remove_child($missile);
            };
        }
    }
}

sub detect_collisions {
    my $self = shift;
    my @collisions = map  { $self->detect_missile_collision($_) }
                     grep { $_->coro }
                            $self->player->all_children;
    return @collisions? \@collisions: undef;
}

sub detect_missile_collision {
    my ($self, $missile) = @_;
    # when distance from missile head to circle center is less than the
    # circle radius, we have a collision
    my $first = first { $_->distance_to($missile->xy) - 8 <= $_->radius }
                grep  { $_->coro }
                        $self->spawner->all_children;
    return $first? [$missile, $first]: ();
}

# ------------------------------------------------------------------------------

package GameFrame::eg::EvilCircle;
use Moose;
use GameFrame::Time qw(animate);

has player => (is => 'ro', required => 1, weak_ref => 1);
has v      => (is => 'ro', required => 1); # velocity of expansion
has radius => (is => 'rw', default  => 1); # start small, then grow
has color  => (is => 'rw', default  => 0xFFFFFFFF);

with 'GameFrame::Role::Point';
with qw(
    GameFrame::Role::Figure
    GameFrame::Role::Movable
    GameFrame::Role::Active::Child
);

sub start {
    my $self = shift;
    # stop growing circle when it reaches player shield
    my $max = $self->distance_to([320, 200]) - 25;
    animate
        type  => [linear => 1, $max, $max],
        on    => [radius => $self],
        sleep => 1 / $self->v;
    # now hit player with 10 HP
    $self->player->hit(10);
}

sub paint {
    my ($self, $surface) = @_;
    $surface->draw_circle($self->xy, $self->radius, $self->color, 1);
}

# ------------------------------------------------------------------------------

package GameFrame::eg::CircleSpawner;
use Moose;
use List::Util qw(max);
use GameFrame::Time qw(interval);

with qw(
    GameFrame::Role::Active
    GameFrame::Role::Container::Simple
    GameFrame::Role::Active::Container
);

sub start {
    my $self = shift;
    my $i = 0;
    interval
        sleep => sub { max(0.2, 1 - $i / 40) },
        step  => sub {
            # select increasing velocity
            my $v = max(70, 20 + $i / 2);

            # select a starting point for the circle from one of the
            # four screen edges
            my ($w, $h) = (640, 480);
            my $x_point = int rand $w * 2 + $h * 2;
            my $y_point = $x_point - $w * 2;
            my ($x, $y) = $y_point < 0?
                ($x_point % $w, $x_point < $w? 0: $h):
                ($y_point < $h? 0: $w, $y_point % $h);
            $self->create_next_child(xy => [$x, $y], v => $v);
            $i++;
        };
}

# ------------------------------------------------------------------------------

package GameFrame::eg::CircleKillMissile;
use Moose;
use Math::Trig;

with 'GameFrame::Role::Point';
with qw(
    GameFrame::Role::Figure
    GameFrame::Role::Movable
    GameFrame::Role::Active::Child
);

has to    => (is => 'ro', required => 1);
has color => (is => 'rw', default  => 0xFFFFFFFF);

sub start {
    my $self = shift;
    my $to = $self->to;
    $self->move(to => sub { $to });
}

sub paint {
    my ($self, $surface) = @_;
    $self->draw_polygon(
       $surface, $self->color,
       [pi*0, 8], [pi*3/4, 5], [pi*5/4, 5],
   );
}

# ------------------------------------------------------------------------------

package GameFrame::eg::CircleKiller;
use Moose;
use Coro;
use Math::Trig;
use Time::HiRes qw(time);

# for benefit of health bar
sub w { 25 }

has last_hit_time => (is => 'rw', default => -1);

with 'GameFrame::Role::Point';

with qw(
    GameFrame::Role::SDLEventHandler
    GameFrame::Role::Figure
    GameFrame::Role::Container::Simple
    GameFrame::Role::Active::Container
    GameFrame::Role::HealthBar
    GameFrame::Role::Scoreable
    GameFrame::Role::Movable
);

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

# when mouse moves we set our angle
sub on_mouse_motion {
    my ($self, $x, $y) = @_;
    my $angle = $self->compute_angle_to($x, $y);
    return unless defined $angle; # cursor too close to center
    $self->angle($angle);
}

# fire!
sub on_mouse_button_up {
    my $self = shift;
    # cant fire more than 4 missiles at once
    return if $self->child_count >= 4;
    $self->create_next_child(
        xy    => $self->translate_point_by_distance(25),
        to    => $self->translate_point_by_distance(300), # range of missile
        angle => $self->angle,
    );
}

sub on_hit { shift->last_hit_time(time) }

sub on_death {
    my $self = shift;
    async {
        $self->move(to => sub { [320, 480] });
        exit;
    };
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
    health_bar_offset => [-13, -25],
    v                 => 100, # velocity when dropping to death
    child_args        => {
        child_class => 'GameFrame::eg::CircleKillMissile',
        v           => 100,
    },
);

# spawns evil circles
my $spawner = GameFrame::eg::CircleSpawner->new(
    child_args  => {
        child_class => 'GameFrame::eg::EvilCircle',
        player      => $player,
    },
);

# detects missle <-> circle collisions and updates score
my $detector = GameFrame::eg::CircleMissileCollisionDetector->new(
   spawner => $spawner,
   player  => $player,
);

$app->run;


