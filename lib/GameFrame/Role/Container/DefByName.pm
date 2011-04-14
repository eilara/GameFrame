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
    default  => sub { [] },
);

# actual child defs as created, not as given in constructor
# could be different if prepare_child_defs changed the defs
# HACK only ready after BUILD so should only be looked
# at during the lifetime of the object not during construction
# could be undef as well if container has no children
has actual_child_defs => (
    is  => 'rw', # ro but set during _build_children
    isa => ArrayRef,
);

has children_by_name => (
    is       => 'ro',
    isa      => HashRef,
    default  => sub { {} },
);

with 'GameFrame::Role::Container';

sub _build_children {
    my $self        = shift;
    my $by_name     = $self->children_by_name;
    my @child_defs  = @{ $self->child_defs };
    my @actual_defs = $self->prepare_child_defs(@child_defs);
    my $it          = natatime 2, @actual_defs;

    $self->actual_child_defs([@actual_defs]);

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
    return $self->children_by_name->{$name} || die "No child [$name]";
}

sub child_names {
    my $self = shift;
    my $defs = $self->actual_child_defs;
    return () unless $defs; # no children in this container

    my $it = natatime 2, @$defs;
    my @names;
    while (my ($name, $child_def) = $it->()) {push @names, $name }
    return @names;
}

1;

