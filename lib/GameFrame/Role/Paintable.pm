package GameFrame::Role::Paintable;

# role for paintable objects
#
# once constructed, the paintable object method paint() (required of
# consumers) will be called once per frame displayed, with no parameters
#
# the responsibility of paint() is drawing things on the surface
# it should not update the object state, or start/stop any Coros
#
# you can draw things in paint() using the surface primitives, e.g.
# $self->draw_rect([0, 0, 100, 100], 0xFFFFFFFF)
# note there is no need to pass the surface
#
# if you still need the surface, you can get it with $self->surface
#
# you can configure paintable objects with a layer, and each will
# be drawn on the correct layer
# the layer manager will paint the layers in the correct order
#
# you can set visibility with is_visible field and show()/hide() methods
# your paint() method will not be called if the paintable is hidden

use Moose::Role;
use MooseX::Types::Moose qw(Bool Str);

# set these two before creating any paintables
my ($Layer_Manager, $SDL_Main_Surface);
sub Set_Layer_Manager    { $Layer_Manager     = shift }
sub Set_SDL_Main_Surface { $SDL_Main_Surface  = shift }

requires 'paint';

has surface => (
    is         => 'ro',
    weak_ref   => 1,
    lazy_build => 1,
    handles    => [qw(draw_gfx_text draw_circle draw_circle_filled
                      draw_line draw_rect)],
);

has layer => ( # layer name
    is       => 'ro',
    isa      => Str,
    default  => 'background',
);

has is_visible => (
    is       => 'rw',
    isa      => Bool,
    default  => 1,
);

# should we call paint on this paintable or will someone else do it
has auto_paint => (
    is       => 'ro',
    isa      => Bool,
    default  => 1,
);

sub show { shift->is_visible(1) }
sub hide { shift->is_visible(0) }

sub _build_surface { $SDL_Main_Surface }

sub sdl_paint {
    my ($self, $surface) = @_;
    return unless $self->{is_visible};
    $self->paint($surface);
}

# permonks stvn trick to get BUILD time action from roles
sub BUILD {}
before 'BUILD' => sub {
    my $self = shift;
    $Layer_Manager->add_paintable_to_layer($self->layer, $self)
        if $self->auto_paint;
};


1;
