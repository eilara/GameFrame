package GameFrame::Role::Sprite;

# a role for a visual object which has a bitmap sprite

use Moose::Role;
use Moose::Util::TypeConstraints;
use MooseX::Types::Moose qw(Int Num Str ArrayRef);
use aliased 'SDLx::Sprite' => 'SDLxSprite';
use aliased 'GameFrame::ImageFile';

coerce ImageFile, from Str, via { ImageFile->new(file => $_) };

has image => (
    is       => 'ro',
    isa      => ImageFile, 
    required => 1,
    coerce   => 1,
    handles  => qr/^build_sdl/,
);

has sprite => (
    is         => 'ro',
    isa        => SDLxSprite,
    lazy_build => 1,
    handles    => {
        draw     => 'draw',
        sprite_x => 'x',
        sprite_y => 'y',
        sprite_w => 'w',
        sprite_h => 'h',
    },
);

with qw(
    GameFrame::Role::Rectangular
    GameFrame::Role::Paintable
);

sub _build_sprite {
   my $self = shift;
   return $self->build_sdl_sprite( $self->size );
}

around xy_trigger => sub {
    my ($orig, $self) = @_;
    my $xy = $self->_actual_xy;
    my $sprite = $self->sprite;
    $sprite->x($xy->[0]);
    $sprite->y($xy->[1]);
};

sub paint {
    my ($self, $surface) = @_;
    $self->draw($surface);
}

1;

