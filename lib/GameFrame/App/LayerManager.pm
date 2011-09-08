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
sub add_paintable_to_layer {
    my ($self, $layer, $paintable) = @_;
    $self->layer_map->{$layer}->add_paintable($paintable);
}

sub paint {
    my $self   = shift;
    my $layers = $self->layer_map;
    my $names  = $self->layers;
    $layers->{$_}->paint for @$names;
}

1;

