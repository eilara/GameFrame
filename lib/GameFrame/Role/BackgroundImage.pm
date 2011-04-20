package GameFrame::Role::BackgroundImage;

# lets a rectangular class have a background image
# the consumer need not be paintable

use Moose::Role;
use GameFrame::MooseX;
use MooseX::Types::Moose qw(Str);

has bg_image       => (is => 'ro');
has bg_image_layer => (is => 'ro', isa => Str, default => 'background');

with 'GameFrame::Role::Rectangular';

compose_from 'GameFrame::Widget::Image',
    prefix => 'bg_sprite',
    inject => {
        xy         => 'xy',
        image_size => 'size',
        image      => 'bg_image',
        layer      => 'bg_image_layer',
    };

sub bg_x { shift->bg_sprite->x(@_) }
sub bg_y { shift->bg_sprite->y(@_) }

# permonks stvn trick to get BUILD time action from roles
sub BUILD {}
after 'BUILD' => sub {
    my $self = shift;
    $self->bg_sprite if $self->bg_image; # instantiate lazy bg_sprite
                                         # optionaly if user wants it
};

1;
