package GameFrame::Role::Event::BoxRouter;

use Moose::Role;
use GameFrame::Role::Event::Sink::Rectangular;

has active_mouse_sink => (
    is  => 'rw',
    isa => 'Undef|GameFrame::Role::Event::Sink::Rectangular',
);

with qw(
    GameFrame::Role::Event::Sink::Rectangular
    GameFrame::Role::Panel::Box
);

# child events handled before parent events

for my $event (qw(mouse_button_up mouse_button_down)) {
    my $method = "on_$event";
    before $method => sub {
        my ($self, @mouse_xy) = @_;
        my $child = $self->_find_listening_child_at(@mouse_xy);
        return unless $child;
        $child->$method(@mouse_xy);

#       print "SEF=$self xy=$mouse_xy[0] $mouse_xy[1] $child\n";
    };
}

# mouse motion handled differently for benefit of mouse enter/leave
before on_mouse_motion => sub {
    my ($self, @mouse_xy) = @_;
    my $child = $self->_find_listening_child_at(@mouse_xy);

    # motion on an area with no children in it should still trigger mouse leave
    unless ($child) {
        $self->_child_mouse_leave;
        return;
    }

    my $active = $self->active_mouse_sink;
    if (!$active || ($active != $child)) {
        $active->on_mouse_leave if $active;
        $self->active_mouse_sink($child);
        $child->on_mouse_enter;
    }
    
    $child->on_mouse_motion(@mouse_xy);
};

before on_mouse_leave => sub { shift->_child_mouse_leave };

before on_app_mouse_focus => sub {
    my ($self, $is_focus) = @_;
    return if $is_focus;
    $self->_child_mouse_leave;
};

sub _child_mouse_leave {
    my $self = shift;
    my $active = $self->active_mouse_sink;
    return unless $active;
    $active->on_mouse_leave;
    $self->active_mouse_sink(undef);
}

sub _find_listening_child_at {
    my ($self, @xy) = @_;
    my $child = $self->find_child_at(@xy);
    return $child
        && $child->does('GameFrame::Role::Event::Sink::Rectangular')
             ? $child
             : undef;
}

1;

