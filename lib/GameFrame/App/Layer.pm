package GameFrame::App::Layer;

use Moose;

with 'MooseX::Role::Listenable' => {event => 'sdl_paint'};

# only called on the layer called new_layer
# empties all paintables from this layer into the correct layer
# from the layer map
sub empty_into_layer_map {
    my ($self, $layers) = @_;
    my $all = $self->_sdl_paint_listeners;
    return unless $all->size;
    for my $l ($all->members) {
        my $layer = $l->layer; # ask the paintable for its layer
        my $final_layer = $layers->{$layer};
        die "No such layer=$layer" unless $final_layer;
        $final_layer->add_sdl_paint_listener($l);
    }
    $all->clear;
}

1;

