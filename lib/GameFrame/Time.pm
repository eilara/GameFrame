package GameFrame::Time::PauseResumeListenable;

use Moose;

with 'MooseX::Role::Listenable' => {event => 'game_paused'};
with 'MooseX::Role::Listenable' => {event => 'game_resumed'};

package GameFrame::Time;

use strict;
use warnings;
#use Sub::Call::Recur; # dont compile on windows
use Set::Object qw(set);
use Coro;
use Coro::EV;
use EV;
use Coro::Timer qw(sleep);
use Time::HiRes qw(time);
use Set::Object::Weak qw(set);
use List::Util qw(max);
use GameFrame::Util qw(distance);
use base 'Exporter';

our @EXPORT_OK = qw(
    rest animate interval poll repeat_work work_while move
    pause_game resume_game pause_resume is_paused cleanup_thread
    add_pause_listener add_resume_listener
);

my $Timers          = {};  # cleaned by cleanup_thread
my $Resume_Signals  = set; # cleaned by resume
my $Is_Paused       = 0;
my $PauseListenable = GameFrame::Time::PauseResumeListenable->new;

sub add_pause_listener {
    my $listener = shift;
    $PauseListenable->add_game_paused_listener($listener);
}

sub add_resume_listener {
    my $listener = shift;
    $PauseListenable->add_game_resumed_listener($listener);
}

# HACK HACK HACK
# 1st coro timer fires TOO SOON
# we start the 1st timer, so the user wont have to start it
# because of this strange coro bug/misunderstanding
# TODO: maybe need to do this on resume as well?
sub init_coros() { sleep 0.001 }
my $init_coros;
$init_coros = sub { init_coros; $init_coros = sub {} };

sub rest {
    my $sleep = shift;
    return unless $sleep > 0.01;
    $init_coros->();
    my $sleep_start = time;
    my $timer = EV::timer $sleep, 0, Coro::rouse_cb;
    $Timers->{$Coro::current} = $timer;
    Coro::rouse_wait;
    delete $Timers->{$Coro::current};
    if ($Is_Paused) {
        $Resume_Signals->insert(my $resume_signal = AnyEvent->condvar);
        my $sleep_left = $sleep - (time - $sleep_start);
        $resume_signal->recv;
#        recur($sleep_left) if $sleep_left > 0.01; # dont compile on windows
        @_ = ($sleep_left);
        goto &rest;

    }
}

sub cleanup_thread($) {
    my $coro = shift;
    delete $Timers->{$Coro::current};
}

sub pause_resume() { if ($Is_Paused) { resume_game() } else { pause_game() } }

sub is_paused() { $Is_Paused }

sub pause_game() {
    $Is_Paused = 1;
    $PauseListenable->game_paused;
    $_->invoke for values %$Timers;
    $Timers = {};
}

sub resume_game() {
    $Is_Paused = 0;
    $PauseListenable->game_resumed;
    $_->send for $Resume_Signals->elements;
    $Resume_Signals->clear;
}

# TODO these are horrible names
#      surely someone somewhere has named these things before

sub work_while {
    my (%args)    = @_;
    my $sleep     = $args{sleep};
    my $predicate = $args{predicate} || 1;
    my $work      = $args{work};
    my $timeout   = $args{timeout};
    my $start     = time;
    my $time_pred = $timeout? sub { time - $start < $timeout }: sub { 1 };
    while ($time_pred->() && $predicate->()) {
        $work->();
        rest $sleep;
    }
}

sub repeat_work(%) {
    my (%args)    = @_;
    my $sleep     = $args{sleep};
    my $predicate = $args{predicate};
    my $work      = $args{work};
    while (1) {
        if ($predicate->()) {
            $work->();
            rest $sleep;
        }
    }
}

sub poll(%) {
    my (%args)    = @_;
    my $sleep     = $args{sleep} || 0.1;
    my $timeout   = $args{timeout};
    my $predicate = $args{predicate};
    my $start     = time;
    my $time_pred = $timeout? sub { time - $start < $timeout }: sub { 1 };
    while ($time_pred->()) {
        rest $sleep;
        if (my $result = $predicate->()) {
            return $result;
        }
    }
    return undef;
}

sub interval(%) {
    my $block;
    my (%args)     = @_;
    my $sleep      = $args{sleep};
    my $times      = $args{times};
    my $step       = $args{step};
    my $start      = $args{start};
	$block         = $start? sub { $start->(@_); $block = $step }: $step;
    my $sleep_code = ref($sleep) eq 'CODE'? $sleep: sub { $sleep };
    if ($times) {
        for my $i (1..$times) {
            $block->($i);
            rest $sleep_code->();
        }
    } else {
        my $i = 1;
        while(1) {
            $block->($i);
            rest $sleep_code->();
            $i++;
        }
    }
}

sub animate(%) {
    my (%args) = @_;
    my $sleep = $args{sleep};
    my ($method, $obj) = @{$args{on}};
    my ($type, $begin, $end, $steps) = @{$args{type}}; 

    my $step = ($end - $begin) / $steps;
    my $value = $begin;
    for (1..$steps) {
        $obj->$method($value);
        $value += $step;
        rest $sleep;
    }
    $obj->$method($end);
}

# set wild to true when target moves around wildly
# it will then be reset to undef 1st time we read it
# and 'can we reach the target' is computed a little differently
#
# returns when: reached destination or to() callback returns undef
#
# TODO: should move as many pixels needed
#       because last sleep was too long? note sometimes uneven
#       distances between creeps because of this
#       should keep a delta and sleep less if needed?

sub move(%) {
    my (%args)    = @_;
    my $xy        = $args{xy};
    my $to        = $args{to};
    my $v_arg     = $args{v};
    my $v_cb      = ref($v_arg) eq 'CODE'? $v_arg: sub { $v_arg };
    my $wild      = $args{wild};
    my $init_to   = $to->();
    return unless $init_to; # target died

    my ($x1, $y1) = @{ $xy->() };
    my ($x2, $y2) = @$init_to;
    $to->(undef) if $wild;
    my ($d, $last_d);

    my $compute_next_xy = $wild
        ? sub { # for wild targets we can't make sure that distance
                # is decreasing when it moves so we undef last_d
            if (my $to_xy = $to->()) {
                ($x2, $y2) = @$to_xy;
                $last_d = undef;
            } else {
                $last_d = $d;
            }
        }: sub {
            if (my $to_xy = $to->()) {
                ($x2, $y2) = @$to_xy;
            }
            $last_d = $d;
        };

    while (
        ($d = distance($x1, $y1, $x2, $y2)) > 1
     && (!$last_d || $last_d >= $d)
    ) {
        my $vel   = $v_cb->();
        my $sleep = max(1/$vel, 1/60); # dont move pixel by 1 pixel if you are fast
        my $step  = $vel * $sleep;
        my $steps = $d / $step;
        last if $steps < 1;
        $x1 += ($x2 - $x1) / $steps;
        $y1 += ($y2 - $y1) / $steps;
        $xy->([$x1, $y1]);

        rest $sleep;
        $compute_next_xy->();
    }

    $xy->([$x2, $y2]);
}

1;

