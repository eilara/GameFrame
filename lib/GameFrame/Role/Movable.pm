package GameFrame::Role::Movable;

# a positionable object with required scalar speed which manages
# a MoveTo animation

use Moose::Role;
use MooseX::Types::Moose qw(CodeRef);
use Scalar::Util qw(weaken);
use GameFrame::Util::Vectors;
use GameFrame::MooseX;
use aliased 'GameFrame::Animation::MoveTo';
use aliased 'GameFrame::Role::Positionable';
use aliased 'GameFrame::Role::Animation';

# speed in pixels per second
has speed => (is => 'rw', required => 1); # isa => Num, 

has destination_getter => (
    traits   => ['Code'],
    is       => 'rw',
    isa      => CodeRef,
    handles => {compute_destination => 'execute'},
);

compose_from MoveTo,
    prefix => 'motion',
    inject => sub {
        my $self = shift;
        weaken $self; # don't want args to hold strong ref to self
        return (target => $self);
    };
# TODO fix moosex role buildinstanceof to support handles in roles
#      then we could make movable animated, but with different
#      prefix on the control methods (e.g. motion) so it can
#      be both animated for some properties, movable for xy

with 'GameFrame::Role::Positionable';

sub move_to {
    my ($self, $to) = @_;
    $self->set_to($to);
    $self->motion->start_animation_and_wait;
}

sub restart_move_to {
    my ($self, $to) = @_;
    $self->set_to($to);
    $self->motion->restart_animation_and_wait;
}

sub start_motion { shift->motion->start_animation }
sub stop_motion  { shift->motion->stop_animation }

# called when reached destination
sub destination_reached {}

sub set_to {
    my ($self, $to) = @_;
    # 'to' can be any code that returns Vector2D, array ref of dim 2,
    # positionable, or Vector2D
    my $to_code = 
        ref($to) eq       'CODE' ? $to:
        ref($to) eq      'ARRAY' ? do { my $vec = V(@$to); sub { $vec } }:
        ref($to) eq Positionable ? do { weaken $to; sub { $to->xy_vec } }:
                                   sub { $to };
    $self->destination_getter($to_code);
}

# returns by how many pixels per second did we slow
# so that spell casters can take away the spell
# TODO there really should a buff/curse class
sub slow {
    my ($self, $percent) = @_;
    my $speed = $self->speed;
    my $delta_speed = $speed * ($percent/100);
    $self->speed($speed - $delta_speed);
    return $delta_speed;
}

sub haste {
    my ($self, $delta_speed) = @_;
    $self->speed($self->speed + $delta_speed);
}

1;


