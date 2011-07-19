package GameFrame::Role::Active::Container;

use Moose::Role;
use Coro;

# a container of active objects
# it itself need not be active
# for it to work, children must do Active::Child
# solves these problems when you need to manage many active objects:
# - its a container, so you can create and add them
# - no need to remove a child when its coro deactivates, it will
#   be cleaned automatically from the container, and this works
#   if the coro start() returns, deactivate() is called from a 
#   different thread, or the coro is transfer()ed to a new sub
#   this way, memory associated with the Active child object is always freed
# - get a notification when children coros are deactivated
# - get a notification when all children have been deactivated
# 
# TODO: do we even need this? active object are referenced by the coro
#       scheduler as lexical state in the code, maybe for active objects
#       you dont need to keep strong refs anywhere
#       true, a weak object set will do fine, but you still need notifications
#       of deactivation perhaps?
#       dont like it that active GOBs have TWO strong refs to them in the system

with 'GameFrame::Role::Container';

around next_child_args => sub {
    my ($orig, $self) = @_;
    return {%{$self->$orig}, parent => $self};
};

after remove_child => sub {
    my ($self, $child) = @_;
    $self->on_child_deactivate($child);
    $self->on_all_children_deactivated unless $self->child_count;
};

sub on_child_deactivate {}

sub on_all_children_deactivated {}

1;


