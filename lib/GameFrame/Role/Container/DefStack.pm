package GameFrame::Role::Container::DefStack;

use Moose::Role;
use MooseX::Types::Moose qw(ArrayRef HashRef);
use Set::Object;

has child_defs => (
    is       => 'ro',
    required => 1,
    isa      => ArrayRef[HashRef],
);

with 'GameFrame::Role::Container';

around next_child_args => sub {
    my ($orig, $self, $idx) = @_;
    my @defs = @{ $self->child_defs };
    return unless $idx < @defs; # no more sorry
    return $defs[$idx];
};

1;

