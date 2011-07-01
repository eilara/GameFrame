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

my $MIN_SLEEP = 1 / 60;

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
has clock => (is => 'ro', isa => Clock, required => 1,
              handles => [qw(now build_periodic_timer)],
              default => sub { Clock->new });

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

# when was last pause started, if in pause
has pause_start_time => (is => 'rw');

# how much to sleep at 1st tick after resume, if paused and resumed in
# middle of tick
has sleep_after_resume => (is => 'rw', default => 0);

# how much time was paused in this cycle
has total_cycle_pause => (is => 'rw', default => 0);

sub _build_timer {
    my $self = shift;
    weaken $self;
    # build a timer with dummy $start_time and $timer_sleep, which we set
    # before start()
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

sub _on_compute_sleep {
    my $self = shift;
    my $elapsed = $self->total_sleep_computed; # elapsed on the timer tick that happens because of this computed sleep
    my $next_elapsed = $elapsed;

    if ($self->sleep_after_resume) {
        $self->sleep_after_resume(undef);
    } else {
        $next_elapsed += $self->cycle_sleep;
    }

    my $next_elapsed_and_pause = $next_elapsed + $self->total_cycle_pause;
    $self->total_sleep_computed($next_elapsed);
#print "S> now=${\( sprintf('%.3f',EV::time() - $self->cycle_start_time) )}, next_elapsed=${\( sprintf('%.3f', $next_elapsed) )}, next_elapsed_and_pause=${\( sprintf('%.3f', $next_elapsed_and_pause) )}  \n";
    return $self->cycle_start_time + $next_elapsed_and_pause;
}

sub _on_first_timer_tick {
    my ($self, $cycle_start_time) = @_;
    $cycle_start_time ||= $self->now;
    $self->cycle_start_time($cycle_start_time);
    $self->set_timer($cycle_start_time, $self->cycle_sleep, 0);
    $self->total_sleep_computed(0);
}

sub _on_timer_tick {
    my $self = shift;
    my $elapsed = $self->now - $self->cycle_start_time;
    $self->total_sleep_computed($elapsed);

    if (my $ideal_cycle_duration = $self->is_cycle_complete($elapsed)) {
        $self->_stop($ideal_cycle_duration);
        $self->cycle_complete;
        $self->_on_final_timer_tick;
        return;
    }

    $self->timer_tick($elapsed);
}

sub _on_final_timer_tick {}

sub start {
    my ($self, $cycle_start_time) = @_;
    $self->_on_first_timer_tick($cycle_start_time);
    $self->start_timer;
    $self->timer_tick(0);
}

sub restart {
    my $self = shift;
    my $last_cycle_complete_time = $self->last_cycle_complete_time;
    die "Can't restart since we have no yet been started and stopped"
        unless $last_cycle_complete_time;
    $self->_on_first_timer_tick($last_cycle_complete_time);
    $self->start_timer;
    $self->timer_tick(0);
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
        ($ideal_cycle_duration || $self->total_sleep_computed)
    );
    $self->$_(0) for qw(
        cycle_start_time
        total_sleep_computed
        sleep_after_resume
        total_cycle_pause
    );
    $self->stop_timer;
}

sub pause {
    my ($self, $pause_start_time) = @_;
    return unless $self->is_timer_active;
    my $now = $pause_start_time || $self->now;
    my $actual_sleep = $now - $self->cycle_start_time - $self->total_cycle_pause;
    $self->sleep_after_resume( $self->total_sleep_computed - $actual_sleep );
    $self->pause_start_time($now);
    $self->stop_timer;
}

sub resume {
    my ($self, $resume_time) = @_;
    return if $self->is_timer_active;
    my $now = $resume_time || $self->now;
    my $pause_time = $now - $self->pause_start_time;
    $self->total_cycle_pause( $self->total_cycle_pause + $pause_time );
    $self->pause_start_time(undef); 
    $self->start_timer;
}

1;
