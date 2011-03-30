package GameFrame::Role::AnimatedSprite;

# the animated sprite role

use Moose::Role;
use MooseX::Types::Moose qw(Num HashRef);
use aliased 'SDL::Rect';
use aliased 'SDLx::Sprite::Animated' => 'SDLxSprite';
use GameFrame::ResourceManager;
use GameFrame::Time qw(interval);

sub x;sub y; # for benefit of Rectangular role
has x => (is => 'rw', required => 1, isa => Num, default => 0, trigger => sub { shift->_update_x});
has y => (is => 'rw', required => 1, isa => Num, default => 0, trigger => sub { shift->_update_y});

has image => (is => 'ro', isa => HashRef, required => 1);

has sprite => (
    is         => 'ro',
    lazy_build => 1,
    handles    => {
        draw               => 'draw',
        sprite_x           => 'x',
        sprite_y           => 'y',
        sprite_w           => 'w',
        sprite_h           => 'h',
        sequence_animation => 'sequence',
        next_animation     => 'next',
    },
);

with qw(
    GameFrame::Role::Rectangular
    GameFrame::Role::Paintable
);

sub _build_sprite {
    my $self = shift;
    my $image = $self->image;
    return SDLxSprite->new(
        image     => image_resource $image->{file},
        rect      => Rect->new(0, 0, @{ $image->{size} }),
        sequences => $image->{sequences},
    );
}

sub animate_sprite {
    my ($self, %args) = @_;
    my ($sequence, $frames, $sleep) = map { $args{$_} } qw(sequence frames sleep);
    interval
        times => $frames,
        sleep => $sleep,
        step  => sub { $self->next_animation },
        start => sub { $self->sequence_animation($sequence) };
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

