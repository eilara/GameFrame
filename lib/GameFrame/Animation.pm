package GameFrame::Animation;

# an animation class for tweens- animation with fixed duration
# and predetermined path and easing not for following moving targets,
# moving with externally changed velocity, or apriori unknown duration
#
# an animation is constructed using a spec:
#
# - duration   - cycle duration in seconds
# - target     - target object with the attribute neing animated
# - attribute  - attribute name on the target
# - forever    - if true, cycle will repeat forever
# - repeat     - set to int number of cycles to repeat
# - bounce     - switch from/to on cycle repeat
# - ease       - easing function defines progress on path vs. time
# - curve      - for >1D animations (e.g. xy of sprite) the name
#                of the curve class that will set the trajectory
#                for the animation
# - curve_args - any arguments for the curve
# - from       - initial value, if not given will be computed from
#                the attribute on the target
# - to         - final value, 'from' will be computed from starting
#                attribute value, only for default linear curve and
#                for linear curve types (e.g. sine)
#
# an animation is built from:
# - Timeline: for which the animation is the provider
#   it calls the methods timer_tick and cycle_complete
#   on this animation
#   it is created with a cycle_limit built from the duration
# - Proxy: the connection to the target, on it we get/set the
#   animated value, consult it concerning the animation
#   resolution for int optimization, and get the 'from' value
# - Easing function: maps elapsed time to progress in the animation
# - Curve: the trajectory of the animation, deault is linear
#
# all the animation does is create the helpers, then convert each
# tick from the timeline to a set attribute on the proxy, by piping
# the elapsed time through the easing function, then through the
# curve to compute the animated value

use Moose;
use MooseX::Types::Moose qw(Bool Num Int Str ArrayRef);
use Scalar::Util qw(weaken);
use Math::Vector::Real;
use GameFrame::MooseX;
use aliased 'GameFrame::Animation::CycleLimit';
use aliased 'GameFrame::Animation::Proxy::Factory' => 'ProxyFactory';
use aliased 'GameFrame::Animation::Proxy';
use aliased 'GameFrame::Animation::Curve' => 'Curve';
use GameFrame::Animation::Curve::Linear;
use GameFrame::Animation::Curve::Circle;
use GameFrame::Animation::Curve::Spiral;
use GameFrame::Animation::Easing;

extends 'GameFrame::Animation::Base';

has from         => (is => 'ro', lazy_build => 1);
has speed        => (is => 'ro', isa => Num, lazy_build => 1);
has duration     => (is => 'ro', isa => Num, lazy_build => 1);
has curve_length => (is => 'ro', isa => Num, lazy_build => 1);
has ease         => (is => 'ro', isa => Str, default => 'linear');

compose_from Proxy,
    has => {handles => [qw(
        set_attribute_value
        get_init_value
        compute_timer_sleep
    )]};

compose_from Curve,
    prefix => 'curve',
    inject => sub {
        my $self = shift;
        return (from => $self->from);
    },
    has => {handles => {
        solve_curve          => 'solve_curve',
        solve_edge_value     => 'solve_edge_value',
        compute_curve_length => 'curve_length',
    }};

sub _build_duration {
    my $self = shift;
    return $self->curve_length / $self->speed;
}

sub _build_speed {
    my $self = shift;
    return $self->curve_length / $self->duration;
}

sub _build_curve_length { shift->compute_curve_length }

sub _suggest_timer_sleep {
    my $self = shift;
    my $speed = $self->curve_length / $self->duration;
    return $self->compute_timer_sleep($speed || 100); # if curve len=0, smallest sleep possible
}

sub _build_cycle_limit {
    my $self = shift;
    return CycleLimit->time_period($self->duration);
}

sub _build_from {
    my $self = shift;
    return $self->get_init_value;
}

sub get_timer_tick_cb {
    my $self = shift;
    weaken $self;
    my $ease   = $self->ease;
    my $easing = $GameFrame::Animation::Easing::{$ease};
    return sub {
        my $elapsed = shift;
        my $time    = $elapsed / $self->duration; # normalized elapsed between 0 and 1
        my $eased   = $easing->($time);
        $eased      = 1 - $eased if $self->is_reversed_dir;
        my $value   = $self->solve_curve($eased);
        $self->set_attribute_value($value);
    };
}

sub cycle_complete {
    my $self = shift;
    $self->set_attribute_value(
        $self->solve_edge_value(
            $self->is_reversed_dir? 0: 1
        )
    );
}

around BUILDARGS => sub {
    my ($orig, $class, %args) = @_;

    die unless $args{duration} || $args{speed};

    # fix from_to
    if (my $from_to = delete($args{from_to})) {
        $args{from} = $from_to->[0];
        $args{to}   = $from_to->[1];
    }

    # fix proxy args
    $args{proxy_args} = [
        target    => delete($args{target}),
        attribute => delete($args{attribute}),
        @{ $args{proxy_args} || []},
    ];
    weaken $args{proxy_args}->[1]; # dont want strong ref to target in args

    $args{proxy_class} ||= ProxyFactory->find_proxy
        (@{ $args{proxy_args} });

    # fix timeline args
    $args{timeline_args} = $args{timeline_args} || [];
    for my $att (qw(repeat bounce forever)) {
        if (exists $args{$att}) {
            my $val = delete $args{$att};
            push @{$args{timeline_args}}, $att, $val;
        }
    }
    
    # fix curve args
    my $curve = delete($args{curve}) || 'linear';
    $curve = join '', map { ucfirst } split(/_/, $curve);
    $args{curve_class} = "GameFrame::Animation::Curve::$curve";

    $args{curve_args} = $args{curve_args} || [];
    if (my $to = delete($args{to})) {
        $to = V(@$to) if ref($to) eq 'ARRAY'; # TODO do the same for 'from'
        push @{$args{curve_args}}, to => $to;
    }

    return $class->$orig(%args);
};

1;

__END__

