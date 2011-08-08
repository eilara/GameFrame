package GameFrame::Widget::Toolbar;

# a panel which adds separators around children

# TODO should hanle background panel support so you dont have to add them manually

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

with qw(
    GameFrame::Role::BackgroundImage
    GameFrame::Role::Event::BoxRouter
);

around BUILDARGS => sub {
    my ($orig, $class, %args) = @_;
    my @defs  = @{$args{child_defs}};
    my $image = $args{separator_image};
    my $layer = $args{layer} || 'background';
    my $it    = natatime 2, @defs;
    my $i;
    my $sep = sub {
        return ('_border_'. ++$i, {
            child_class => Image,
            w           => 1,
            image       => $image,
            layer       => $layer,
        });
    };
    my @new_defs = ($sep->());
    while (my ($name, $child_def) = $it->())
        { push @new_defs, ($name, $child_def, $sep->()) }
    $args{child_defs} = \@new_defs;
    return $class->$orig(%args);
};

1;

