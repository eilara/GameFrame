package GameFrame::Role::Panel::Box;

# a rectangular DefByName container of rectangular children
# according to the orientation, sets w/h/x/y of children so they are 
# arranged one after the other
# like a simple HTML row layout with no wrapping
# each rectangular child must have a width defined for horizontal orientation
# or a height for vertical orientation
# if it does not, it will stretch- it will accept all left over space

use Moose::Role;
use MooseX::Types::Moose qw(Str);
use List::MoreUtils qw(natatime);

# TODO make into an enumeration type
has orientation => (
    is      => 'ro',
    isa     => Str,
    default => 'horizontal',
);

# we are paintable so that consumers can attach bg image to paint
# we dont paint anything ourselves
with qw(
    GameFrame::Role::Paintable
    GameFrame::Role::Rectangular
    GameFrame::Role::Container::DefByName
);

around prepare_child_defs => sub {
    my ($orig, $self, @defs) = @_;
    my ($size, $orth_size, $place, $orth_place) =
        $self->_orientation_selectors;
    my ($total_size, $at) = (0, 0);
    my @flex_children;
    @defs = $self->$orig(@defs);

    # pass 1: sum child sizes
    my $it1 = natatime 2, @defs;
    while (my ($name, $child_def) = $it1->()) {
        if (my $child_size = delete $child_def->{size}) {
            ($child_def->{w}, $child_def->{h}) = @$child_size;
        }
        $child_def->{$orth_size}  = $self->$orth_size;
        $child_def->{$orth_place} = $self->$orth_place;
        my $child_def_size        = $child_def->{$size};

        if ($child_def_size) {
            $total_size += $child_def_size;
        } else { # a flex child, no size given
            push @flex_children, $child_def;
        }
    }

    # set sizes on flex children
    if (@flex_children) {
        my $left_over      = $self->$size - $total_size;
        my $flex_width     = int($left_over / scalar @flex_children);
        my $flex_width_mod = $left_over % scalar @flex_children;
        for my $child_def (@flex_children) {
            $child_def->{$size} = $flex_width + ($flex_width_mod-- > 0? 1: 0);
        }
    }

    # pass 2: distribute position among children
    my $it2 = natatime 2, @defs;
    while (my ($name, $child_def) = $it2->()) {
        $child_def->{$place}  = $at;
        $at                  += $child_def->{$size};
    }
    
    return @defs;
};

# TODO this will be slow for too many children
sub find_child_at {
    my ($self, $x, $y) = @_;
    my ($size, undef, $place) = $self->_orientation_selectors;
    my $pos = $self->is_horizontal? $x: $y; 
    for my $name ($self->child_names) {
        my $child = $self->child($name);
        return $child if (
                ($child->$place + $child->$size >  $pos)
             && ($child->$place                 <= $pos)
        );
    }
    return undef;
}

sub _orientation_selectors {
    my $self          = shift;    
    my $is_horizontal = $self->is_horizontal;
    my $size          = $is_horizontal? 'w': 'h';
    my $orth_size     = $is_horizontal? 'h': 'w';
    my $place         = $is_horizontal? 'x': 'y';
    my $orth_place    = $is_horizontal? 'y': 'x';
    return ($size, $orth_size, $place, $orth_place);
}

sub is_horizontal { shift->orientation eq 'horizontal' }

sub paint {}

1;

