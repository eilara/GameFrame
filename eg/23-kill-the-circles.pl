#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../lib";

# note the use of the Figure role, a paintable positionable thing
# with handy vector drawing methods and an angle at which it points

# ------------------------------------------------------------------------------

package GameFrame::eg::EvilCircle;
use Moose;
use GameFrame::Util::Vectors;

has player => (is => 'ro', required => 1, weak_ref => 1);
has speed  => (is => 'ro', required => 1); # velocity of expansion
has radius => (is => 'rw', default  => 1); # start small, then grow
has color  => (is => 'rw', default  => 0xFFFFFFFF);

with qw(
    GameFrame::Role::Paintable
    GameFrame::Role::Positionable
    GameFrame::Role::Animated
    GameFrame::Role::Active::Child
);

sub start {
    my $self = shift;
    # expand until we reach player shield
    my $distance = abs($self->xy_vec - V(320, 200)) - 25;
    $self->animate({
        attribute => 'radius',
        to        => $distance,
        duration  => ($distance / $self->speed),
        ease      => 'swing',
    });
    # now hit player with 10 HP
#  $self->player->hit(10);
}

sub paint {
    my $self = shift;
    $self->draw_circle($self->xy, $self->radius, $self->color, 1);
}

# ------------------------------------------------------------------------------

package GameFrame::eg::CircleSpawner;
use Moose;
use List::Util qw(min);
use GameFrame::Util::Vectors;

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
    my ($orig, $self) = @_;
    return {
        %{$self->$orig},
        speed  => min(200, 20 + $self->next_child_idx*3), # increase speed
        xy_vec => random_edge_vector V(640, 480),
    };
};

# ------------------------------------------------------------------------------

package GameFrame::eg::CircleKillMissile;
use Moose;
use Math::Trig;

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
    $self->move_to($self->to);
}

sub paint {
    my $self = shift;
    $self->draw_polygon_polar(
       $self->color,
       [pi*0, 8], [pi*3/4, 5], [pi*5/4, 5],
   );
}

# ------------------------------------------------------------------------------
package GameFrame::eg::CircleKiller;
use Moose;
use GameFrame::Util::Vectors;

has last_hit_time => (is => 'rw', default => -1);

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
   $self->draw_circle($self->xy, 25, $color, 1);
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

    my $angle = $self->angle;
    my $from  = $self->xy_vec + VP($angle, 25);
    my $to    = $self->xy_vec + VP($angle, 300); # missle range=300

    $self->create_next_child(
        xy_vec => $from,
        to     => $to,
        angle  => $angle,
    );
}

sub on_hit { shift->last_hit_time(time) }

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
        speed       => 200,
    },
);

# spawns evil circles
my $spawner = GameFrame::eg::CircleSpawner->new(
    child_args  => {
        child_class => 'GameFrame::eg::EvilCircle',
        player      => $player,
    },
);



 
 # # detects missle <-> circle collisions and updates score
 # my $detector = GameFrame::eg::CircleMissileCollisionDetector->new(
 #    spawner => $spawner,
 #    player  => $player,
 # );
 # 
$app->run;


__END__


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

