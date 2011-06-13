package GameFrame::Role::Active;

use Moose::Role;
use Coro;
#use GameFrame::Time qw(cleanup_thread);

# active objects have a coro and must implement start()
# a new coro is created on construction which runs your start()

requires 'start';

has coro => (
    is       => 'rw',
    isa      => 'Coro',
    required => 1,
    weak_ref => 1, # coro scheduler has a ref to the coro, if it lives
    default  => sub { my $self = shift; return async { $self->start } },
);

# should only be called from a different thread than the one deactivated
# and only when that thread is active but sleeping
sub deactivate {
    my $self = shift;
    my $coro = $self->coro;
    $coro->cancel;
#    cleanup_thread($coro);
}

1;


