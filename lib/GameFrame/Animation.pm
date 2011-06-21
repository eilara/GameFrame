package GameFrame::Animation;

# an animation is constructed using a spec:
#
# - one of the two:
#   - from_to   - array ref of initial and final values
#   - to        - final value, 'from' will be computed from starting
#                 attribute value
# - one of the two:
#   - duration  - cycle duration in seconds
#   - speed     - absolute value of average speed used to compute duration 
# - target    - target object with the attribute neing animated
# - attribute - attribute name on the target
# - forever   - if true, cycle will repeat forever
# - repeat    - set to int number of cycles to repeat
# - bounce    - switch from/to on cycle repeat
# - curve     - easing function defines progress on path vs. time
#

use Moose;
use Scalar::Util qw(weaken);
use MooseX::Types::Moose qw(Bool Num Int Str ArrayRef);
use GameFrame::MooseX;
use aliased 'GameFrame::Animation::Timer';
use aliased 'GameFrame::Animation::CycleLimit';
use aliased 'GameFrame::Animation::Curve';
use aliased 'GameFrame::Animation::Proxy::Factory' => 'ProxyFactory';
use aliased 'GameFrame::Animation::Proxy';

use aliased 'Coro::Signal';

has duration  => (is => 'ro', isa => 'Num'     , lazy_build => 1);
has from_to   => (is => 'ro', isa => 'ArrayRef', lazy_build => 1);

has speed     => (is => 'ro', isa => 'Num'); # optional instead of duration
has to        => (is => 'ro');               # optional instead of from_to

has forever   => (is => 'ro', isa => Bool, default => 0);
has bounce    => (is => 'ro', isa => Bool, default => 0);
has curve     => (is => 'ro', isa => Str , default => 'linear');

# filpped on bounce
has is_reversed_dir  => (
    traits  => ['Bool'],
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
    handles => {toggle_dir => 'toggle', set_forward_dir => 'unset'},
);

# repeat counter decreases by 1 every cycle iteration
has repeat => (
    traits  => ['Counter'],
    is      => 'ro',
    isa     => 'Int',
    default => 1,
    handles => {dec_repeat => 'dec'},
);

# signals to outside listener of animation complete, wait for it with
# wait_for_animation_complete() method
has animation_complete_signal => (
    is      => 'ro',
    default => sub { Signal->new },
    handles => {
        wait_for_animation_complete  => 'wait',
        broadcast_animation_complete => 'broadcast',
    },
);

compose_from Timer,
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
        start_animation      => 'start',
        restart_animation    => 'restart',
        stop_timer           => 'stop',
        pause_animation      => 'pause',
        resume_animation     => 'resume',
        is_animation_started => 'is_timer_active',
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

sub stop_animation {
    my $self = shift;
    $self->stop_timer;
    $self->_animation_complete;
}

sub timer_tick {
    my ($self, $elapsed) = @_;
    my $new_value = $self->compute_value_at($elapsed);
    $self->set_attribute_value($new_value);
}

sub cycle_complete {
    my $self = shift;
    $self->set_attribute_final_value;
    if ($self->forever or $self->repeat > 1) {
        $self->dec_repeat unless $self->forever;
        $self->reverse_dir if $self->bounce;
        $self->restart_animation;
    } else {
        $self->_animation_complete;
    }
}

sub _animation_complete {
    my $self = shift;
    $self->set_forward_dir;
    $self->broadcast_animation_complete;
}

sub set_attribute_final_value {
    my $self = shift;
    $self->set_attribute_value($self->compute_final_value);
}

sub reverse_dir {
    my $self = shift;
    $self->toggle_dir;
}

sub compute_final_value {
    my $self = shift;
    return $self->from_to->[$self->is_reversed_dir? 0: 1];
}

sub compute_value_at {
    my ($self, $elapsed) = @_;
    my $easing   = $self->curve;
    my @from_to  = @{ $self->from_to };
    @from_to     = reverse(@from_to) if $self->is_reversed_dir;
    my $time     = $elapsed / $self->duration; # normalized elapsed between 0 and 1
    my $delta    = $from_to[1] - $from_to[0];
    return Curve->$easing($time, $from_to[0], $delta);
}

around BUILDARGS => sub {
    my ($orig, $class, %args) = @_;

    $args{proxy_args} = [
        target    => delete($args{target}),
        attribute => delete($args{attribute}),
        ($args{proxy_args} || ()),
    ];

    $args{proxy_class} = ProxyFactory->find_proxy(@{ $args{proxy_args} });

    return $class->$orig(%args);
};

1;

__END__

