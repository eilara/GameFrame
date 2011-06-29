package GameFrame::Animation;

# an animation is constructed using a spec:
#
# - one of the two, from_to or to:
#   - from_to   - array ref of initial and final values
#   - to        - final value, 'from' will be computed from starting
#                 attribute value
# - one of the two, duration or speed:
#   - duration  - cycle duration in seconds
#   - speed     - absolute value of average speed used to compute duration 
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
use aliased 'GameFrame::Animation::Easing';
use aliased 'GameFrame::Animation::Proxy::Factory' => 'ProxyFactory';
use aliased 'GameFrame::Animation::Proxy';

has duration => (is => 'ro', isa => 'Num'     , lazy_build => 1);
has from_to  => (is => 'ro', isa => 'ArrayRef', lazy_build => 1);
has speed    => (is => 'ro', isa => 'Num'); # optional instead of duration
has to       => (is => 'ro');               # optional instead of from_to
has ease     => (is => 'ro', isa => Str , default => 'linear');

compose_from Timeline,
    inject => sub {
        my $self = shift;
        weaken $self; # don't want args to hold strong ref to self
        return (
            cycle_limit => CycleLimit->time_period($self->duration),
            provider    => $self,
            $self->_compute_timer_sleep,
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

with 'GameFrame::Role::Animation';

sub _build_duration { # if duration was not given we calculate it from speed
    my $self = shift;
    my $speed = $self->speed;
    die "Can't start animation with no speed or duration specified"
        unless $speed;
    my @from_to  = @{ $self->from_to };
    my $delta    = $from_to[1] - $from_to[0];
    my $duration = abs($delta) / $speed;
    return $duration;
}

sub _build_from_to { # if from_to was not given we compute 'from'
    my $self = shift;
    my $to = $self->to;
    die "Can't compute from_to if 'to' is not given" unless defined $to;
    return [$self->get_init_value, $to];
}

sub _compute_speed {
    my $self     = shift;
    my @from_to  = @{ $self->from_to };
    my $delta    = $from_to[1] - $from_to[0];
    my $speed    = abs($delta) / $self->duration;
    return $speed;
}

sub _compute_timer_sleep {
    my $self = shift;
    return $self->compute_timer_sleep($self->_compute_speed);
}

sub timer_tick {
    my ($self, $elapsed) = @_;
    my $new_value = $self->compute_value_at($elapsed);
    $self->set_attribute_value($new_value);
}

sub cycle_complete {
    my $self = shift;
    $self->set_attribute_final_value;
}

sub set_attribute_final_value {
    my $self = shift;
    $self->set_attribute_value($self->compute_final_value);
}

sub compute_final_value {
    my $self = shift;
    return $self->from_to->[$self->is_reversed_dir? 0: 1];
}

sub compute_value_at {
    my ($self, $elapsed) = @_;
    my $easing      = $self->ease;
    my @from_to     = @{ $self->from_to };
    @from_to        = reverse(@from_to) if $self->is_reversed_dir;
    my ($from, $to) = @from_to;
    my $time        = $elapsed / $self->duration; # normalized elapsed between 0 and 1
    my $delta       = $to - $from;
    my $eased       = Easing->$easing($time);
    my $value       = $from + $eased * $delta;
    return $value;
}

around BUILDARGS => sub {
    my ($orig, $class, %args) = @_;

    $args{proxy_args} = [
        target    => delete($args{target}),
        attribute => delete($args{attribute}),
        ($args{proxy_args} || ()),
    ];

    $args{proxy_class} = ProxyFactory->find_proxy
        (@{ $args{proxy_args} });

    $args{timeline_args} = [ $args{timeline_args} || () ];
    for my $att (qw(repeat bounce forever)) {
        if (exists $args{$att}) {
            my $val = delete $args{$att};
            push @{$args{timeline_args}}, $att, $val;
        }
     }

     return $class->$orig(%args);
};

1;

__END__

