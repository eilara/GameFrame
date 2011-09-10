package GameFrame::App::Layer;

use Moose;
use Scalar::Util qw(weaken);

has children => (is => 'rw', default => sub { [] });

sub add_paintable {
    my ($self, $paintable) = @_;
    my $children = $self->children;
    unshift @$children, $paintable;
    weaken $children->[0];
}

sub paint {
    my $self = shift;
    my $children = $self->children;
    my $are_dead;
    # we need to clean dead weak refs
    for my $child (@$children) {
        if ($child)        { $child->paint }
        elsif (!$are_dead) { $are_dead = 1 }
    }
    if ($are_dead) {
        my $new_children = [grep { defined $_ } @$children];
        weaken($new_children->[$_]) for 1..scalar(@$new_children);
    }
}

1;

