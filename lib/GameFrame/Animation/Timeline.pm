package GameFrame::Animation::Timeline;

# a timeline is a timer with better control of time. It adds to timer:
#
# - wait_for_animation_complete
# - cycle repeat control / forever
# - control the direction of time with bounce or is_reversed_dir
#

use Moose;
use MooseX::Types::Moose qw(Bool Num Int Str);
use aliased 'Coro::Signal';

extends 'GameFrame::Animation::Timer';

has bounce  => (is => 'ro', isa => Bool , default => 0);
has forever => (is => 'ro', isa => Bool , default => 0);

# repeat counter decreases by 1 every cycle iteration
has repeat => (
    traits  => ['Counter'],
    is      => 'ro',
    isa     => 'Int',
    default => 1,
    handles => {dec_repeat => 'dec'},
);

# filpped on bounce
has is_reversed_dir  => (
    traits  => ['Bool'],
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
    handles => {toggle_dir => 'toggle', set_forward_dir => 'unset'},
);

# signals to outside listener of animation complete, wait for it with
# wait_for_animation_complete() method
has animation_complete_signal => (
    is      => 'ro',
    default => sub { Signal->new },
    handles => {
        _wait_for_animation_complete => 'wait',
        broadcast_animation_complete => 'broadcast',
    },
);

after stop => sub {
    my $self = shift;
    $self->_animation_complete;
};

sub _on_final_timer_tick {
    my $self = shift;
    if ($self->forever or $self->repeat > 1) {
        $self->dec_repeat unless $self->forever;
        $self->toggle_dir if $self->bounce;
        $self->restart;
    } else {
        $self->_animation_complete;
    }
}

sub wait_for_animation_complete {
    my $self = shift;
    return unless $self->is_timer_active;
    $self->_wait_for_animation_complete;
}

# call to signify animation has completed or animation has been stopped
sub _animation_complete {
    my $self = shift;
    $self->set_forward_dir;
    $self->broadcast_animation_complete;
}

1;

__END__


