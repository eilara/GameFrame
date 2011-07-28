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
has velocity      => (is => 'ro', default => sub { V(0, 0) }); # player velocity
                                                               # for collision detection

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
    my $to_from  = $to - $from;
    my $velocity = normalize_vector($to_from) * $speed;
    my $duration = $dist / $speed;

    $self->create_next_child(
        xy_vec   => $from,
        to       => $to,
        angle    => $angle,
        speed    => $speed,
        velocity => $velocity,
        duration => $duration,
    );
}

sub on_hit { shift->last_hit_time(time) }

# ------------------------------------------------------------------------------

package GameFrame::eg::CircleKillMissile;
use Moose;
use Math::Trig;

with qw(
    GameFrame::Role::Living
    GameFrame::Role::Figure
    GameFrame::Role::Movable
    GameFrame::Role::Active::Child
);

has detector => (is => 'ro', required => 1);
has to       => (is => 'ro', required => 1);
has color    => (is => 'rw', default  => 0xFFFFFFFF);
has radius   => (is => 'ro', default  => 8);
has velocity => (is => 'ro', required => 1); # for benefit of detector
has duration => (is => 'ro', required => 1); # for benefit of detector

sub start {
    my $self = shift;
    $self->detector->missile_fired($self);
    my $to = $self->to;
    $self->move_to($self->to);

    return unless $self->is_alive; # if we are dead, then we failed and are lost
                                   # no circle was hit by this missile

    $self->detector->missile_lost($self);
}

sub collide_with_circle {
    my $self = shift;
    $self->accept_death;
    $self->stop_motion;
}

sub paint {
    my $self = shift;
    $self->draw_polygon_polar(
       $self->color,
       [pi*0, $self->radius], [pi*3/4, 5], [pi*5/4, 5],
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
    my $circle_velocity = ($to - $from) / $duration;
    return {
        %{$self->$orig},
        xy_vec         => $from,
        radius         => $circle_radius,
        velocity       => $circle_velocity,
        animation_args => [
            attribute => 'xy_vec',
            to        => $to,
            duration  => $duration,
        ],
    };
};

# ------------------------------------------------------------------------------

package GameFrame::eg::EvilCircle;
use Moose;
use MooseX::Types::Moose qw(Int);
use GameFrame::MooseX;
use aliased 'GameFrame::Animation';
 
has detector => (is => 'ro', required => 1);
has player   => (is => 'ro', required => 1, weak_ref => 1);
has radius   => (is => 'rw', isa => Int, required => 1);
has velocity => (is => 'rw', required => 1);
has color    => (is => 'rw', default  => 0xFFFFFFFF);

with qw(
    GameFrame::Role::Paintable
    GameFrame::Role::Positionable
    GameFrame::Role::Living
    GameFrame::Role::Active::Child
);

compose_from Animation,
    inject => sub { (target => shift) },
    has    => {handles => [qw(start_animation_and_wait stop_animation duration)]};

sub start {
    my $self = shift;
    $self->detector->circle_spawned($self);

    $self->start_animation_and_wait;
    return unless $self->is_alive; # if we are dead, then we did not get to player
#   $self->player->hit(10);        # if we are alive, hit player

    $self->detector->circle_reached_goal($self);
}

sub collide_with_missile {
    my $self = shift;
    $self->accept_death;
    $self->stop_animation;
}

sub paint {
    my $self = shift;
    $self->draw_circle($self->xy, $self->radius, $self->color, 1);
}

# ------------------------------------------------------------------------------

package GameFrame::eg::CircleMissileCollisionDetector;
use Moose;
use List::Util qw(min);
use Set::Object::Weak qw(weak_set);
use GameFrame::Util::Vectors;

has [qw(circles missiles)] => (is => 'ro', default => sub { weak_set });

sub circle_spawned {
    my ($self, $circle) = @_;
#    foreach my $missile ($self->missiles->members) {
#        my $time_to_impact = detect_dynamic_collision(circle_to_circle =>
#            $missile, $circle, min($circle->duration, $missile->duration));
##   print "$missile, $circle, $time_to_impact\n";
#        next unless defined $time_to_impact;
#        $self->add_collision($missile, $circle, $time_to_impact);
#    }
    $self->circles->insert($circle);
}

sub circle_reached_goal {
    my ($self, $circle) = @_;
    $self->circles->remove($circle);
}

sub missile_fired {
    my ($self, $missile) = @_;
    foreach my $circle ($self->circles->members) {
        my $time_to_impact = detect_dynamic_collision(circle_to_circle =>
            $missile, $circle, min($circle->duration, $missile->duration));
        next unless defined $time_to_impact;
        $self->add_collision($missile, $circle, $time_to_impact);
    }
    $self->missiles->insert($missile);
}

sub missile_lost {
    my ($self, $missile) = @_;
    $self->missiles->remove($missile);
}

sub add_collision {
    my ($self, $missile, $circle, $time) = @_;
   print "$missile, $circle, $time\n";
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

# detects collisions
my $detector = GameFrame::eg::CircleMissileCollisionDetector->new;

# the player is the circle killer, its children are missiles
my $player = GameFrame::eg::CircleKiller->new(
    xy                => [320, 200],
    start_hp          => 50,
    health_bar        => [-13, -25, 22, 2],
    speed             => 100, # speed when dropping to death
    child_args        => {
        child_class => 'GameFrame::eg::CircleKillMissile',
        start_hp    => 1,
        detector    => $detector,
    },
);

# spawns evil circles
my $spawner = GameFrame::eg::CircleSpawner->new(
    child_args  => {
        child_class => 'GameFrame::eg::EvilCircle',
        player      => $player,
        start_hp    => 1,
        detector    => $detector,
    },
);

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

