package GameFrame::Widget::Toolbar;

# a panel which adds separators around children

# TODO should hanle background panel support so you dont have to add them manually

# HACK quite a bit of mechanism just for overriding prepare_child_defs
# and changing the child defs

use Moose;
use MooseX::Types::Moose qw(Str);
use List::MoreUtils qw(natatime);
use aliased 'GameFrame::Widget::Image';

# Str filename or ImageFile if you want stretching of the image
has separator_image => (is => 'ro', required => 1);

# TODO toolbar should be paintable composite and layer, visibility,
#      etc. should be given to children
has layer => ( # layer name
    is       => 'ro',
    isa      => Str,
    default  => 'background',
);

# need to add DefByName so that we can wrap around prepare_child_defs
# BEFORE we consume the Box role, which also wraps this method
# and we want our wrapping to happen 1st
with qw(
    GameFrame::Role::BackgroundImage
    GameFrame::Role::Container::DefByName
);

around prepare_child_defs => sub {
    my ($orig, $self, @defs) = @_;
    my $it = natatime 2, $self->$orig(@defs);
    my $i;
    my $sep = sub {
        return ('_border_'. ++$i, {
            child_class => Image,
            w           => 1,
            image       => $self->separator_image,
            layer       => $self->layer,
        });
    };
    my @new_defs = ($sep->());
    while (my ($name, $child_def) = $it->())
        { push @new_defs, ($name, $child_def, $sep->()) }
    return @new_defs;
};

# we want to apply the layout AFTER we add separators
with 'GameFrame::Role::Event::BoxRouter';

1;

