package GameFrame::Role::Container::Simple;

use Moose::Role;
use MooseX::Types::Moose qw(HashRef);

has child_args => (
    is       => 'rw',
    isa      => HashRef,
    required => 1,
);

with 'GameFrame::Role::Container';

around next_child_args => sub {
    my ($orig, $self) = @_;
    return $self->child_args;
};

1;

