package GameFrame::Role::Container::DefByName;

# a container that creates all its children on construction
# it is immutable, you cannot insert/remove children
# you can access its children by name 
# HACK LSP violation alert- Role::Container is mutable

use Moose::Role;
use MooseX::Types::Moose qw(ArrayRef HashRef);
use List::MoreUtils qw(natatime);

# array ref of name => child def pairs
# TODO trigger is bad with non lazy param because you dont know the order of
#      setting the attributes if some other attribute has a trigger
#      better is around some container method
has child_defs => (
    is       => 'ro',
    required => 1,
    isa      => ArrayRef,
    trigger  => sub { shift->_build_children },
);

has children_by_name => (
    is       => 'ro',
    isa      => HashRef,
    default  => sub { {} },
);

with 'GameFrame::Role::Container';

sub _build_children {
    my $self       = shift;
    my $by_name    = $self->children_by_name;
    my @child_defs = @{ $self->child_defs };
    my $it         = natatime 2, $self->prepare_child_defs(@child_defs);

    while (my ($name, $child_def) = $it->()) {
        my $child = $self->create_next_child(%$child_def);
        $by_name->{$name} = $child;
    }
}

sub prepare_child_defs {
    my ($self, @defs) = @_;
    return @defs;
}

sub child {
    my ($self, $name) = @_;
    return $self->children_by_name($name) || die "No child [$name]";
}

1;

