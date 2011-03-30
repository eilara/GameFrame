package GameFrame::Role::Active::Child;

use Moose::Role;
use MooseX::Types::Moose qw(Int);
use aliased 'GameFrame::Role::Active::Container';
use Coro;

# an active object which is a child of an Active::Container
# it will remove itself from its parent when deactivated so that memory
# will be freed

has parent => (is => 'ro', required => 1, does => Container, weak_ref => 1);
has idx    => (is => 'ro', required => 1, isa  => Int); # index in parent

with 'GameFrame::Role::Active';

# TODO:
# - exceptions in start()
# - deactivate() called
# - transfer() called
after start => sub { shift->remove_from_parent };

sub remove_from_parent {
    my $self = shift;
    $self->parent->remove_child($self);
}

1;

