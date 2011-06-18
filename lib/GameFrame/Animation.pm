package GameFrame::Animation;

# an animation is constructed using a spec:
#
# - from_to   - array ref of initial and final values
# - one of the two:
#   - duration  - cycle duration in seconds
#   - speed - absolute value of average speed used to compute duration 
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
use aliased 'GameFrame::Animation::Proxy';

use aliased 'Coro::Signal';

my $MIN_SLEEP = 1 / 100;

has duration  => (is => 'ro', isa => 'Num', required => 1);
has from_to   => (is => 'ro', isa => 'ArrayRef', required => 1);

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

compose_from Proxy, has => {handles => [qw(set_attribute_value)]};

with 'GameFrame::Role::Animation';

sub stop_animation {
    my $self = shift;
    $self->stop_timer;
    $self->_animation_complete;
}

# TODO resolution,by,sleep
sub compute_sleep {
    my ($self, $elapsed) = @_;
    return $MIN_SLEEP; 
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

    if (my $speed = delete $args{speed}) {
        my @from_to = @{ $args{from_to} };
        my $delta   = $from_to[1] - $from_to[0];
        $args{duration} = $delta / $speed;
    }

    $args{proxy_args} = [
        target    => delete($args{target}),
        attribute => delete($args{attribute}),
        ($args{proxy_args} || ()),
    ];

    return $class->$orig(%args);
};

1;

__END__

# TODO <= depends on attribute type!!!!!!!!!!!!
#print "computing value: from=$from delta=$delta elapsed=$elapsed normalized_elapsed=$normalized_elapsed\n";


# normalize from/to/speed/duration
around BUILDARGS => sub {
    my ($orig, $class, %args) = @_;

    my $from_to = $args{from_to};
    my $has_from_to = exists $args{from_to};
    die "'from_to' is not an ArrayRef of [from,to]"
        if $from_to && (ref($from_to) ne 'ARRAY');
    $args{from} = $from_to->[0] unless exists $args{from};

    # TODO check: bounce must have limit or to

    unless (exists $args{speed}) {
        die "'from_to' is missing, can't compute speed"
            unless $has_from_to;
        my ($from, $to) = @{ $from_to };
        # TODO <= depends on attribute type!!!!!!!!!!!!
        die "Duration cannot be zero" unless $args{duration};
        $args{speed} = ($to - $from) / $args{duration};
    }

     unless ($args{limit}) {
        if ($has_from_to || exists($args{duration}) ) {
            my $to = $has_from_to?
                     $from_to->[1]:
                     $class->compute_value_at($args{duration}, $args{speed}, $args{from});
            $args{limit} = sub { shift->compute_limit_predicate(pop, $to) };
        } else {
            $args{limit} = sub { 1 };
        }
    }

    return $class->$orig(%args);
};


print "Cycle tick: ";    
my $n =  EV::now; $n = sprintf("%.2f", $n);
my $x = sprintf("%.2f", $elapsed);
my $v = sprintf("%.2f", $new_value); print "now=$n t=$x  time=".EV::time()." value=$v\n";


    # 1st reversal we remember original spec, needed when restarting
    unless ($self->orig_spec) {
        $self->orig_spec({
            map {
                my $method = $_;
                ($method => $self->$method);
            } qw(speed from from_to limit)
        });
    }
#use Data::Dumper;print "Reversing, orig_spec=".Dumper($self->orig_spec)."\n";
# TODO <= depends on attribute type!!!!!!!!!!!!
    $self->speed( -1 * $self->speed );
    $self->from( $self->compute_final_value );
    $self->from_to([reverse @$from_to]) if $from_to;
    $self->limit(sub { shift->compute_limit_predicate(pop, $to) });

# TODO <= depends on attribute type!!!!!!!!!!!!
sub compute_sleep { max(1/abs(shift->speed), $MIN_SLEEP) }

