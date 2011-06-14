package GameFrame::Animation;

# an animation is constructed using a spec:
#
# - from_to   - array ref of initial and final values
# - duration  - cycle duration in seconds
# - target    - target object with the attribute neing animated
# - attribute - attribute name on the target
# - forever   - if true, cycle will repeat forever
# - repeat    - set to int number of cycles to repeat
# - bounce    - switch from/to on cycle repeat
#
# TODO: - wait_for_animation_complete will never return if animation is not started
#       - integer value optimization
#       - path, collection of from_to
#       - more duration types, e.g. for move by keypress, moves forever
#         or with direction vector, duration as num of ticks for sprite?
#       - sprite animation
#       - color animation
#       - move in circle? easing functions
#       - float animation on opacity
#       - interval animation for spawning- sets wave num? int
#         must be only on distinct in this case, int optimization

use Moose;
use Scalar::Util qw(weaken);
use MooseX::Types::Moose qw(Bool Num Int Str ArrayRef);
use GameFrame::MooseX;
use aliased 'GameFrame::Animation::Timer';

use aliased 'Coro::Signal';

my $MIN_SLEEP = 1 / 100;

has duration  => (is => 'ro', isa => 'Num', required => 1);
has from_to   => (is => 'ro', isa => 'ArrayRef', required => 1);

has target    => (is => 'ro', required => 1, weak_ref => 1);
has attribute => (is => 'ro', isa => Str, required => 1);
              
has forever   => (is => 'ro', isa => Bool, default => 0);
has bounce    => (is => 'ro', isa => Bool, default => 0);

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
            duration_args => [duration => $self->duration],
            provider      => $self,
        );
    },
    has => { handles => {
        start_animation      => 'start',
        restart_animation    => 'restart',
        stop_timer           => 'stop',
        pause_animation      => 'pause',
        resume_animation     => 'resume',
        is_animation_started => 'is_timer_active',
    },
};

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

sub set_attribute_value {
    my ($self, $value) = @_;
    my $att = $self->attribute;
#print "Setting value: $value\n";
    $self->target->$att($value);
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
    my $from_to = $self->from_to;
    $from_to = [reverse @$from_to] if $self->is_reversed_dir;
    my $from = $from_to->[0];
    my $delta = $from_to->[1] - $from;
    my $normalized_elapsed = $elapsed / $self->duration;
    return $from + $delta * $normalized_elapsed;
}

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

