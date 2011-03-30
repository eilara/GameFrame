package GameFrame::Role::Container;

use Moose::Role;
use MooseX::Types::Moose qw(Int ArrayRef HashRef);
use Set::Object;

has children => (
    is       => 'ro',
    isa      => 'Set::Object',
    default  => sub { Set::Object->new },
    handles  => {
        insert_child => 'insert',
        remove_child => 'remove',
        all_children => 'members',
        child_count  => 'size',
    },
);

has next_child_idx => (is => 'rw', isa => Int , default => 0);

with 'MooseX::Role::Listenable' => {event => 'child_created'};

sub _update_next_child_idx {
    my $self = shift;
    my $idx = $self->next_child_idx;
    $self->next_child_idx($idx + 1);
    return $idx;
}

sub create_next_child {
    my ($self, @args) = @_;
    my $dyna_args     = $self->next_child_args($self->next_child_idx) || return;
    my %child_def     = (@args, %$dyna_args);
    my $child_class   = delete $child_def{child_class};
    my $idx           = $self->_update_next_child_idx;
    my %final_args    = (@args, %child_def, idx => $idx);
    my $child         = $child_class->new(%final_args);

    $self->insert_child($child);

    # fire child_created event with parent, child
    $self->child_created($self, $child);

    return $child;
}

sub next_child_args { {} }


1;

