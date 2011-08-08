package GameFrame::Role::BackgroundImage;

# lets a rectangular paintable class have a background image

use Moose::Role;
use GameFrame::MooseX;

has bg_image       => (is => 'ro');
has bg_image_layer => (is => 'ro');

with qw(
    GameFrame::Role::Paintable
    GameFrame::Role::Rectangular
);

compose_from 'GameFrame::Widget::Image',
    prefix => 'bg_sprite',
    inject => sub {
        my $self = shift;
        return (
            # dont register for auto painting, we will paint ourselves
            # this is all so that bg image can paint BEFORE its consumer
            # thus staying in the background
            auto_paint => 0,
            rect       => $self->rect,
            image      => $self->bg_image,
            layer      => ($self->bg_image_layer || $self->layer),
        );
    };
 
# TODO should set on trigger of xy
sub bg_x { shift->bg_sprite->x(@_) }
sub bg_y { shift->bg_sprite->y(@_) }

before paint => sub {
    my $self = shift;
    $self->bg_sprite->paint if $self->bg_image;
};

1;
