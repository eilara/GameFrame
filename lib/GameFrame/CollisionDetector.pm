package GameFrame::CollisionDetector;

use Moose;
use Scalar::Util qw(weaken);
use GameFrame::MooseX;
use aliased 'GameFrame::Animation';
use aliased 'GameFrame::Role::Container';
use aliased 'GameFrame::Role::Positionable';
use aliased 'GameFrame::Animation::Proxy::Int' => 'IntProxy';

has [qw(container_1 container_2)] => (is => 'ro', does => Container);

has [qw(child_1 child_2)] => (is => 'ro', does => Positionable);

has [qw(group_1_getter group_2_getter)] => (is => 'rw');

# TODO should just use a timeline here
compose_from Animation,
    inject => sub {
        my $self = shift;
        weaken $self;
        my $group_1_getter =
            $self->container_1? sub { shift->container_1->all_children }:
                                sub { (shift->child_1) };
        my $group_2_getter =
            $self->container_2? sub { shift->container_2->all_children }:
            $self->child_1    ? sub { (shift->child_1) }:
                                sub { (shift->child_2) };

        $self->group_1_getter($group_1_getter);
        $self->group_2_getter($group_2_getter);

        return (
            target      => $self,
            attribute   => 'detect_collisions',
            proxy_class => IntProxy,
            forever     => 1,
            duration    => 10, # reset timer every 10 secs
            from_to     => [1, 10 * 60], # about 60 checks a sec
        );
    },
    has => {handles => [qw(start_animation_and_wait stop_animation)]};

with 'GameFrame::Role::Active';

sub start {
    my $self = shift;
    $self->start_animation_and_wait; # forever
}

sub detect_collisions {
    my $self = shift;
    my @collisions = map { $self->detect_collision($_) }
                     map { my $gob_1 = $_;
                          map { [$gob_1, $_] }
                          grep { $_->is_alive }
                          $self->group_2_getter->($self);
                     }
                     grep { $_->is_alive }
                     $self->group_1_getter->($self);
    for my $collision (@collisions) {
        my ($gob_1, $gob_2) = @$collision;
        $_->collide for $gob_1, $gob_2;
    }
}

sub detect_collision {
    my ($self, $gobs) = @_;
    my ($gob_1, $gob_2) = @$gobs;
    my $dist = ($gob_1->xy_vec - $gob_2->xy_vec)->abs -
                $gob_1->radius - $gob_2->radius;
    return $dist <= 1? $gobs: ();
}

1;

