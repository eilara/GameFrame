package GameFrame::Animation;

# an animation is constructed using a spec:
#
# - to        - final value, 'from' will be computed from starting
#               attribute value
# - duration  - cycle duration in seconds
# - target    - target object with the attribute neing animated
# - attribute - attribute name on the target
# - forever   - if true, cycle will repeat forever
# - repeat    - set to int number of cycles to repeat
# - bounce    - switch from/to on cycle repeat
# - ease      - easing function defines progress on path vs. time
#
# an animation is built from:
# - Timeline: for which the animation is the provider
#   it calls the methods timer_tick and cycle_complete
#   on this animation
#   it is created with a cycle_limit built from the duration
# - Proxy: the connection to the target, on it we get/set the
#   animated value, consult it concerning the animation
#   resolution for int optimization, and get the 'from' value
#
# all the animation does is create the 2 correctly, and then
# convert calls from the timeline into values on the proxy

use Moose;
use Scalar::Util qw(weaken);
use MooseX::Types::Moose qw(Bool Num Int Str ArrayRef);
use GameFrame::MooseX;
use aliased 'GameFrame::Animation::Timeline';
use aliased 'GameFrame::Animation::CycleLimit';
use aliased 'GameFrame::Animation::Proxy::Factory' => 'ProxyFactory';
use aliased 'GameFrame::Animation::Curve::Linear'  => 'Curve';
use aliased 'GameFrame::Animation::Proxy';
use GameFrame::Animation::Easing;

has from     => (is => 'ro', lazy_build => 1);
has duration => (is => 'ro', isa => Num, required => 1);
has ease     => (is => 'ro', isa => Str, default => 'linear');

compose_from Timeline,
    inject => sub {
        my $self = shift;
        weaken $self; # don't want args to hold strong ref to self
        my $speed = $self->curve_length / $self->duration;
        return (
            cycle_limit => CycleLimit->time_period($self->duration),
            provider    => $self,
            $self->compute_timer_sleep($speed),
        );
    },
    has => {handles => {
        start_animation             => 'start',
        restart_animation           => 'restart',
        stop_animation              => 'stop',
        pause_animation             => 'pause',
        resume_animation            => 'resume',
        is_animation_started        => 'is_timer_active',
        wait_for_animation_complete => 'wait_for_animation_complete',
        is_reversed_dir             => 'is_reversed_dir',
    },
};

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
        return (
            from => $self->from,
        );
    },
    has => {handles => [qw(
        solve_curve
        solve_edge_value
        curve_length
    )]};

with 'GameFrame::Role::Animation';

sub _build_from {
    my $self = shift;
    return $self->get_init_value;
}

sub timer_tick {
    my ($self, $elapsed) = @_;
    my $new_value = $self->compute_value_at($elapsed);
    $self->set_attribute_value($new_value);
}

sub cycle_complete {
    my $self = shift;
    $self->set_attribute_value($self->solve_edge_value);
}

sub compute_value_at {
    my ($self, $elapsed) = @_;
    my $ease   = $self->ease;
    my $time   = $elapsed / $self->duration; # normalized elapsed between 0 and 1
    my $easing = $GameFrame::Animation::Easing::{$ease};
    my $eased  = $easing->($time);
    $eased     = 1 - $eased if $self->is_reversed_dir;
    my $value  = $self->solve_curve($eased);
    return $value;
}

around BUILDARGS => sub {
    my ($orig, $class, %args) = @_;

    # fix proxy args
    $args{proxy_args} = [
        target    => delete($args{target}),
        attribute => delete($args{attribute}),
        @{ $args{proxy_args} || []},
    ];

    $args{proxy_class} = ProxyFactory->find_proxy
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
#    $args{curve_class} ||= 'linear';
    $args{curve_args} = $args{curve_args} || [];
    if (my $to = delete($args{to})) {
        push @{$args{curve_args}}, to => $to;
    }

    return $class->$orig(%args);
};

1;

__END__

