package GameFrame::Role::Sprite;

# a role for a visual object which has a birmap sprite

use Moose::Role;
use MooseX::Types::Moose qw(Num Str);
use aliased 'SDLx::Sprite' => 'SDLxSprite';
use GameFrame::ResourceManager;

sub x;sub y; # for benefit of Rectangular role
has x => (is => 'rw', required => 1, isa => Num, default => 0, trigger => sub { shift->_update_x});
has y => (is => 'rw', required => 1, isa => Num, default => 0, trigger => sub { shift->_update_y});

has image => (is => 'ro', isa => Str, required => 1);

has sprite => (
    is         => 'ro',
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
    return SDLxSprite->new(image => image_resource $self->image);
}

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

