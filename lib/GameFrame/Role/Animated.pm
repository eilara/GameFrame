package GameFrame::Role::Animated;

# animated object can run animations
#
# the simplest way is by calling animate(), with the animation spec hash ref
# this will block until the animation is complete
#
# if you want finer control over the animation, e.g. start/stop/pause/resume
# the animation, then you can use the create_animation() form, which also
# takes an animation spec, but does not start it or block until it is complete
# all it does is return the animation, so you can do anything you want with it
#
# both forms can take an array ref of animation specs, instead of a single spec
# in this case a composite animation is created, composed of animations created
# by the provided list of specs
# the composite animation will run the animations in parallel

use Moose::Role;
use Scalar::Util qw(weaken);
use aliased 'GameFrame::Animation';
use aliased 'GameFrame::Animation::Composite';

sub animate {
    my ($self, $spec) = @_;
    my $ani = $self->create_animation($spec);
    $ani->start_animation_and_wait;
}

sub create_animation {
    my ($self, $spec) = @_;
    return ref($spec) eq 'ARRAY'?
           $self->_create_composite_animation($spec):
           $self->_create_single_animation($spec);
}

sub create_move_animation {
    my ($self, $spec) = @_;
    $spec->{attribute} = 'xy_vec';
    $self->_create_single_animation($spec);
}

sub _create_single_animation {
    my ($self, $spec) = @_;
    # somebody could be keeping $spec around, dont want to keep a strong
    # ref to the target just because of that silly reason
    weaken($spec->{target} ||= $self);
    return Animation->new(%$spec);
}

sub _create_composite_animation {
    my ($self, $spec) = @_;
    my $parent = Composite->new;
    my @children = map { $self->_create_single_animation($_) } @$spec;
    $parent->add_animations(@children);
    return $parent;        
}

1;


