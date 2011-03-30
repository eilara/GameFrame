package GameFrame::Role::Panel::Box;

# a rectangular DefByName container of rectangular children
# according to the orientation, sets w/h/x/y of children so they are 
# arranged one after the other
# like a simple HTML row layout with no wrapping
# each rectangular child must have a width defined for horizontal orientation
# or a height for vertical orientation

use Moose::Role;
use MooseX::Types::Moose qw(Str);
use List::MoreUtils qw(natatime);

# TODO make into an enumeration type
has orientation => (
    is      => 'ro',
    isa     => Str,
    default => 'horizontal',
);

with qw(
    GameFrame::Role::Rectangular
    GameFrame::Role::Container::DefByName
);

around prepare_child_defs => sub {
    my ($orig, $self, @defs) = @_;
    my ($size, $orth_size, $place, $orth_place) =
        $self->_orientation_selectors;
    my $it = natatime 2, @defs;
    my $at = 0;

    while (my ($name, $child_def) = $it->()) {
        $child_def->{$orth_size}  = $self->$orth_size;
        $child_def->{$orth_place} = $self->$orth_place;
        $child_def->{$place}      = $at;
        $at                       += $child_def->{$size};
    }
    return @defs;
};

# TODO this will be slow for too many children
sub _find_child_at {
    my ($self, $x, $y) = @_;
    my ($size, undef, $place) = $self->_orientation_selectors;
    my $pos = $self->is_horizontal? $x: $y; 
    for my $child ($self->all_children) {
        return $child if (
            ($child->$place + $child->$size >  $pos)
         && ($child->$place                 <= $pos)
        );
    }
    die "Can't find child: no child at $x, $y";
}

sub _orientation_selectors {
    my $self                 = shift;    
    my $is_horizontal        = $self->is_horizontal;
    my $size                 = $is_horizontal? 'w': 'h';
    my $orth_size            = $is_horizontal? 'h': 'w';
    my $place                = $is_horizontal? 'x': 'y';
    my $orth_place           = $is_horizontal? 'y': 'y';
    return ($size, $orth_size, $place, $orth_place);
}

sub is_horizontal { shift->orientation eq 'horizontal' }

1;

