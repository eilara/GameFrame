package GameFrame::Animation::Timer;

use Moose;
use MooseX::Types::Moose qw(Num CodeRef);
use Scalar::Util qw(weaken);
use GameFrame::MooseX;
use aliased 'GameFrame::Animation::Clock';

# a timer
# 
# construct with a provider object and a cycle limit callback
# default timer sleep is 1/60th of a sec, which you can override by setting
# cycle_sleep
#
# The provider must implement timer_tick and cycle_complete
# they will be called with 1 parameter- the time elapsed since the start of the cycle
# not including pause time
#
# the cycle limit will be called before each timer tick and must return
# true when the cycle is to be stopped
# when it does, no more ticks will be called for the timer in this cycle
#
# timer_tick will be called each time the timer ticks with the real elapsed time since
# cycle start
#
# cycle_complete will be called right after the cycle limit callback turns true
# 
# the timer ticks forever, or until stopped
#
# this is just like EV::periodic, except:
# - adds pause/resume feature
# - adds the idea of time elapsed since start of cycle, and start/stop
#   resets the cycle elapsed time, and cycle can complete
# - actual clock+timer is external, so can be tested
#
# TODO:
# * start while paused???
# * is_active while paused???
# * elastic time

my $MIN_SLEEP = 1 / 50;

has provider => (is => 'ro', required => 1, weak_ref => 1, handles => [qw(
    timer_tick
    cycle_complete
)]);

has cycle_sleep => (is => 'ro', isa => Num, default => $MIN_SLEEP);

has cycle_limit => (
    traits   => ['Code'],
    is       => 'ro',
    isa      => 'CodeRef',
    required => 1,
    handles => {is_cycle_complete => 'execute'},
);

# provide a virtual clock for testing, or a shared clock for playing
# with elastic time (TODO)
# or just let each timer create its on clock, which is the default
has clock => (is => 'ro', isa => Clock, lazy_build => 1,
              handles => [qw(now build_periodic_timer)]);

has timer => (is => 'ro', lazy_build => 1, handles => {
    start_timer     => 'start',
    stop_timer      => 'stop',
    set_timer       => 'set',
    is_timer_active => 'is_active',
});

# when did current cycle start
has cycle_start_time => (is => 'rw');

# when did the last cycle complete, in case we are restarting a cycle
has last_cycle_complete_time => (is => 'rw');

# sum of all sleep performed so far in cycle
has total_sleep_computed => (is => 'rw', default => 0);

# when was last tick
has last_tick_time => (is => 'rw', default => 0);

# when was last pause started, if in pause
has pause_start_time => (is => 'rw');

# TODO support for big sleep cycles, sleep_after_resume
# how much to sleep at 1st tick after resume, if paused and resumed in
# middle of tick
# has sleep_after_resume => (is => 'rw', default => 0);

# how much time was paused in this cycle
has total_cycle_pause => (is => 'rw', default => 0);

sub _build_clock { Clock->new }

sub _build_timer {
    my $self = shift;
    weaken $self;
    # build a dummy timer which we reconfigure _on_first_timer_tick
    return $self->build_periodic_timer
        (0, 1, sub { $self->_on_timer_tick });
}

# if cycle sleep is given, default it, in case it is too small
around BUILDARGS => sub {
    my ($orig, $class, %args) = @_;
    my $cycle_sleep = $args{cycle_sleep};
    delete($args{cycle_sleep})
        if $cycle_sleep && ($cycle_sleep < $MIN_SLEEP);
    return $class->$orig(%args);
};

sub DEMOLISH { shift->stop_timer }

sub _on_first_timer_tick {
    my ($self, $cycle_start_time) = @_;
    $cycle_start_time ||= $self->now;
    $self->cycle_start_time($cycle_start_time);
    $self->last_tick_time($cycle_start_time);
    $self->total_sleep_computed(0);
    $self->set_timer($cycle_start_time, $self->cycle_sleep, 0);
}

sub _on_timer_tick {
    my $self  = shift;
    my $now   = $self->now;
    my $delta = $self->now - $self->last_tick_time;
    $self->last_tick_time($now);

    my $elapsed = $now -
                  $self->cycle_start_time -
                  $self->total_cycle_pause;
    $self->total_sleep_computed($elapsed);

    # successful completion of the animation cycle
    if (my $ideal_cycle_duration = $self->is_cycle_complete($elapsed, $delta)) {
        $self->_stop($ideal_cycle_duration);
        $self->cycle_complete;
        $self->_on_final_timer_tick;
        return;
    }

    $self->timer_tick($elapsed, $delta);
}

sub _on_final_timer_tick {}

sub start {
    my ($self, $cycle_start_time) = @_;
    $self->_on_first_timer_tick($cycle_start_time);
    $self->start_timer;
    $self->timer_tick(0, 0);
}

sub restart {
    my $self = shift;
    my $last_cycle_complete_time = $self->last_cycle_complete_time;
    die "Can't restart since we have no yet been started and stopped"
        unless $last_cycle_complete_time;
    $self->_on_first_timer_tick($last_cycle_complete_time);
    $self->start_timer;
    $self->timer_tick(0, 0);
}

# stop is split into _stop and stop: _stop is called when cycle
# is complete, stop is called when timer is to be stopped in middle
# of cycle
sub stop {
    my $self = shift;
    $self->_stop;
}

sub _stop {
    my ($self, $ideal_cycle_duration) = @_;
    # remember the last cycle start time in case we want to restart
    # and avoid timer drift
    $self->last_cycle_complete_time(
        $self->cycle_start_time +
        ($ideal_cycle_duration || $self->total_sleep_computed) +
        $self->total_cycle_pause
    );
    $self->$_(0) for qw(
        cycle_start_time
        total_sleep_computed
        last_tick_time
        total_cycle_pause
    );
# TODO support sleep after resume for when sleep cycle is big
# sleep_after_resume

    $self->stop_timer;
}

sub pause {
    my ($self, $pause_start_time) = @_;
    return unless $self->is_timer_active;

    my $now = $pause_start_time || $self->now;

# TODO support sleep after resume for when sleep cycle is big
#    my $cycle_start_time     = $self->cycle_start_time;
#    my $total_cycle_pause    = $self->total_cycle_pause;
#    my $total_sleep_computed = $self->total_sleep_computed + $self->cycle_sleep;
#    my $actual_sleep         = $now - $cycle_start_time - $total_cycle_pause;
#    my $sleep_after_resume   = $total_sleep_computed - $actual_sleep;
#    $self->sleep_after_resume($sleep_after_resume);

    $self->pause_start_time($now);

    $self->stop_timer;
#    print "PAUSING now=$now actual_sleep=$actual_sleep cycle_start_time=$cycle_start_time total_cycle_pause=$total_cycle_pause sleep_after_resume=$sleep_after_resume total_sleep_computed=$total_sleep_computed\n";
}

sub resume {
    my ($self, $resume_time) = @_;
    return unless $self->pause_start_time; # we are not paused
    return if     $self->is_timer_active;  # we are not active

    my $now = $resume_time || $self->now;
    my $pause_time = $now - $self->pause_start_time;
    $self->total_cycle_pause( $self->total_cycle_pause + $pause_time );
    $self->pause_start_time(undef); 
    $self->last_tick_time($now);
    $self->start_timer;
    $self->_on_timer_tick;
}

1;
