package GameFrame::App::LayerManager;

use Moose;
use MooseX::Types::Moose qw(Str ArrayRef HashRef);
use aliased 'GameFrame::App::Layer';

# layer names in order from front to back
has layers => (
    is       => 'ro',
    required => 1,
    isa      => ArrayRef[Str],
    default  => sub { [] },
);

# map of layer name -> layer listenable
has layer_map => (
    is         => 'ro',
    lazy_build => 1,
    isa        => HashRef[Layer],
);

# layer with paintables not yet added to a specific layer
# needed because when added, paintables dont have a layer name yet
# so we add them to the correct layer on paint, and then
# remove them from this layer
# by paint() time, all paintables have a layer that we can ask
# them about
has new_layer => (
    is       => 'ro',
    required => 1,
    default  => sub { Layer->new },
    handles  => {empty_new_layer => 'empty_into_layer_map'},
);

sub _build_layer_map {
    my $self = shift;
    return {map { $_ => Layer->new } @{ $self->layers }};
}

sub BUILD {
    my $self = shift;
    unshift @{ $self->layers }, 'background'; # auto add background layer
}

# called by paintables to register themselves for painting in
# the correct layer
# since we dont know the correct layer yet, we put them in the
# new_layer for now
sub add_sdl_paint_listener {
    my ($self, $listener) = @_;
    $self->new_layer->add_sdl_paint_listener($listener);
}

sub paint {
    my ($self, $surface) = @_;
    my $layers = $self->layer_map;
    # now empty the new_layer into the layer map
    $self->empty_new_layer($layers);
    # fire the sdl_paint event for each layer from back to front
    $layers->{$_}->sdl_paint($surface) for @{$self->layers};
}

1;

