package GameFrame::App;

# create an App (only ONE app) to open the game window and init the game
# loop
# configure with title, size, bg_color, resource dir, and layer manager
# args
# wraps SDLx::App and Coro controller, should be the only place that
# accesses them
# works with the Paintable, SDLEventHandler roles
# composed from the ResourceManager and the LayerManager, to support
# resource loading and paint layering respectively

use Moose;
use MooseX::Types::Moose qw(Bool Int Str ArrayRef);

use SDL::Events;
use SDL::Mouse;
use SDLx::App;
use aliased 'SDLx::Controller::Coro' => 'Controller';

use GameFrame::MooseX;
use GameFrame::Role::Paintable;
use GameFrame::Role::SDLEventHandler;
use GameFrame::ResourceManager;
use aliased 'GameFrame::App::LayerManager';

has title => (
    is       => 'ro',
    required => 1,
    isa      => Str,
    default  => 'GameFrame',
);

has size => (
    is       => 'ro',
    required => 1,
    isa      => ArrayRef[Int],
    default  => sub { [640, 480] },
);
sub w { shift->size->[0] }
sub h { shift->size->[1] }

# if set, we fill entire app every paint with this color
has bg_color => (is => 'rw', isa => Int);

# resources dir path
has resources => (is => 'ro', isa => Str);

# if set, we hide OS cursor in game window
has hide_cursor => (is => 'ro', isa => Bool, required => 1, default => 0);

compose_from 'SDLx::App',
    prefix => 'sdl',
    has    => {handles => [qw(update stop)]},
    inject => [qw(w h title)];

# the SDLx Coro controller we are wrapping
compose_from Controller, prefix => 'controller';

# our helper for managing layers, the layer manager
compose_from LayerManager,
    prefix => 'layer_manager',
    has    => {handles => [qw(add_sdl_paint_listener paint)]};

# all SDL events are fired through this event
with 'MooseX::Role::Listenable' => {event => 'sdl_event'};

sub BUILD {
    my $self = shift;

    # must be called before creating paintables or sdl event handlers
    GameFrame::Role::Paintable::Set_SDL_Paint_Observable($self);
    GameFrame::Role::Paintable::Set_SDL_Main_Surface($self->sdl);
    GameFrame::Role::SDLEventHandler::Set_SDL_Event_Observable($self);
    GameFrame::ResourceManager::Set_Path($self->resources)
        if defined $self->resources;
}

sub run {
    my $self = shift;
    my $sdl = $self->sdl; # must be created before controller add_event_handler
    my $c = $self->controller;
    $c->add_show_handler(sub { $self->sdl_paint_handler });
    $c->add_event_handler(sub { $self->sdl_event_handler(@_) });
    SDL::Mouse::show_cursor(SDL_DISABLE) if $self->hide_cursor;
    $c->run; # blocks
}

#use EV; my $t = EV::time;
sub sdl_paint_handler {
#print ((EV::time - $t)."\n"); $t=EV::time;
    my $self = shift;
    my $c = $self->bg_color;
    $self->sdl->draw_rect(undef, $c) if defined $c;
    $self->paint;
    $self->update;
}

sub sdl_event_handler {
    my ($self, $e) = @_;
    if ($e->type == SDL_QUIT) {
        $self->stop;
        exit;
    }
    $self->sdl_event($e);
}

1;

__END__
