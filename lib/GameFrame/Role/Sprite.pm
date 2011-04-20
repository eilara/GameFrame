package GameFrame::Role::Sprite;

# a role for a visual object which has a bitmap sprite

use Moose::Role;
use Moose::Util::TypeConstraints;
use MooseX::Types::Moose qw(Int Num Str ArrayRef);
use aliased 'SDLx::Sprite' => 'SDLxSprite';
use aliased 'GameFrame::ImageFile';

coerce ImageFile, from Str, via { ImageFile->new(file => $_) };

sub x;sub y; # for benefit of Rectangular role
has x => (is => 'rw', required => 1, isa => Num, default => 0, trigger => sub { shift->_update_x});
has y => (is => 'rw', required => 1, isa => Num, default => 0, trigger => sub { shift->_update_y});

has image => (
    is       => 'ro',
    isa      => ImageFile, 
    required => 1,
    coerce   => 1,
    handles  => ['build_sdl_sprite'],
);

# optional, useful because it is passed on to the ImageFile sprite builder
# and ImageFile may want to stretch the image to this size
has image_size => (is => 'ro', isa => ArrayRef[Int]);

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

sub _build_sprite { $_[0]->build_sdl_sprite($_[0]->image_size) }

sub w { shift->sprite_w }
sub h { shift->sprite_h }

sub _update_x {
    my $self = shift;
    $self->sprite_x($self->actual_x);
}

sub _update_y {
    my $self = shift;
    $self->sprite_y($self->actual_y);
};

sub paint {
    my ($self, $surface) = @_;
    $self->draw($surface);
}

1;

