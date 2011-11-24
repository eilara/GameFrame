#!/usr/bin/perl


package profile::GameLoop::Controller;
use strict;
use warnings;
use Carp;
use Time::HiRes;
use SDL;
use SDL::Event;
use SDL::Events;
use SDL::Video;
use SDLx::Controller::Interface;
use SDLx::Controller::State;
use Scalar::Util 'refaddr';

# inside out, so this can work as the superclass of another
# SDL::Surface subclass
my %_dt;
my %_min_t;
my %_current_time;
my %_stop;
my %_event;
my %_event_handlers;
my %_move_handlers;
my %_show_handlers;
my %_sleep_cycle;
my %_eoq;
my %_paused;

sub new {
	my ($self, %args) = @_;
	if(ref $self) {
		bless $self, ref $self;
	}
	else {
		my $a;
		$self = bless \$a, $self;
	}

	my $ref = refaddr $self;

	$_dt{ $ref }                 = defined $args{dt}    ? $args{dt}    : 0.1;
	$_min_t{ $ref }              = defined $args{min_t} ? $args{min_t} : 1 / 60;
#	$_current_time{ $ref }       = $args{current_time} || 0; #no point
	$_stop{ $ref }               = $args{stop};
	$_event{ $ref }              = $args{event} || SDL::Event->new();
	$_event_handlers{ $ref }     = $args{event_handlers} || [];
	$_move_handlers{ $ref }      = $args{move_handlers}  || [];
	$_show_handlers{ $ref }      = $args{show_handlers}  || [];
	$_sleep_cycle{ $ref }		 = $args{delay};
	$_eoq{$ref} 				 = $args{exit_on_quit} || $args{eoq} || 0;
#	$_paused{ $ref }             = $args{paused}; #read only

	return $self;
}


sub run {
	my ($self)       = @_;
	my $ref          = refaddr $self;
	my $dt           = $_dt{ $ref };
	my $min_t        = $_min_t{ $ref };
	my $t            = 0.0;

	#Allows us to do stop and run
	$_stop{ $ref } = 0;

	$_current_time{ $ref } = Time::HiRes::time;
	while ( !$_stop{ $ref } ) {
		$self->_event($ref);

		my $new_time   = Time::HiRes::time;
		my $delta_time = $new_time - $_current_time{ $ref };
		next if $delta_time < $min_t;
		$_current_time{ $ref} = $new_time;
		my $delta_copy = $delta_time;

		while ( $delta_copy > $dt ) {
			$self->_move( $ref, 1, $t ); #a full move
		$delta_copy -= $dt;
			$t += $dt;
		}
		my $step = $delta_copy / $dt;
		$self->_move( $ref, $step, $t ); #a partial move
		$t += $dt * $step;

		$self->_show( $ref, $delta_time );

		$dt    = $_dt{ $ref};    #these can change
		$min_t = $_min_t{ $ref}; #during the cycle
		SDL::delay( $_sleep_cycle{ $ref } ) if $_sleep_cycle{ $ref };
	}

}


sub pause {
	my ($self, $callback) = @_;
	my $ref = refaddr $self;
	$callback ||= sub {1};
	my $event = SDL::Event->new();
	$_paused{ $ref} = 1;
	while(1) {
		SDL::Events::wait_event($event) or Carp::confess("pause failed waiting for an event");
		if($callback->($event, $self)) {
			$_current_time{ $ref} = Time::HiRes::time; #so run doesn't catch up with the time paused
			last;
		}
	}
	delete $_paused{ $ref};
}

sub _event {
	my ($self, $ref) = @_;
	SDL::Events::pump_events();
	while ( SDL::Events::poll_event( $_event{ $ref} ) ) {
		$self->_exit_on_quit( $_event{ $ref}  ) if $_eoq{$ref};
		foreach my $event_handler ( @{ $_event_handlers{ $ref} } ) {
			next unless $event_handler;
			$event_handler->( $_event{ $ref}, $self );
		}
	}
}

sub _move {
	my ($self, $ref, $move_portion, $t) = @_;
	foreach my $move_handler ( @{ $_move_handlers{ $ref} } ) {
		next unless $move_handler;
		$move_handler->( $move_portion, $self, $t );
	}
}

sub _show {
	my ($self, $ref, $delta_ticks) = @_;
	foreach my $show_handler ( @{ $_show_handlers{ $ref} } ) {
		next unless $show_handler;
		$show_handler->( $delta_ticks, $self );
	}
}

sub stop { $_stop{ refaddr $_[0] } = 1 }

sub dt {
	my ($self, $arg) = @_;
	my $ref = refaddr $self;
	$_dt{ $ref} = $arg if defined $arg;

	$_dt{ $ref};
}

sub min_t {
	my ($self, $arg) = @_;
	my $ref = refaddr $self;
	$_min_t{ $ref} = $arg if defined $arg;

	$_min_t{ $ref};
}

sub current_time {
	my ($self, $arg) = @_;
	my $ref = refaddr $self;
	$_current_time{ $ref} = $arg if defined $arg;

	$_current_time{ $ref};
}

sub paused {
	$_paused{ refaddr $_[0]};
}


1;

__END__


