package GameFrame::Role::Paintable;

use Moose::Role;
use MooseX::Types::Moose qw(Bool Str);

# set this before creating any paintables
my $SDL_Paint_Observable;
sub Set_SDL_Paint_Observable { $SDL_Paint_Observable = shift }

requires 'paint';

has sdl_paint_observable => (
    is       => 'ro',
    weak_ref => 1,
    required => 1,
    default  => sub { shift->_build_sdl_paint_observable },
);

has layer => ( # layer name
    is       => 'ro',
    required => 1,
    isa      => Str,
    default  => 'background',
);

has is_visible => (
    is       => 'rw',
    required => 1,
    isa      => Bool,
    default  => 1,
);

sub show { shift->is_visible(1) }
sub hide { shift->is_visible(0) }

sub _build_sdl_paint_observable {
    my $self = shift;
    $SDL_Paint_Observable->add_sdl_paint_listener($self);
    return $SDL_Paint_Observable;
}

sub sdl_paint {
    my ($self, $surface) = @_;
    return unless $self->is_visible;
    $self->paint($surface);
}

1;
