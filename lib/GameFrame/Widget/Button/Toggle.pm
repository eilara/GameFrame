package GameFrame::Widget::Button::Toggle;

# a rectangular button

use Moose;
use MooseX::Types::Moose qw(Bool);

extends 'GameFrame::Widget::Button';

has is_toggled => (is => 'rw', isa => Bool, default => 0);

sub toggle_on {
    my $self = shift;
    return if $self->is_toggled;
    $self->_set_button_depth(2);
    $self->is_toggled(1);
}

sub toggle_off {
    my $self = shift;
    return unless $self->is_toggled;
    $self->_set_button_depth(-2);
    $self->is_toggled(0);
}

sub on_mouse_button_down {
    my $self = shift;
    return if $self->is_pressed || $self->is_disabled;
    $self->_set_button_depth($self->is_toggled? 1: 3);
    $self->is_pressed(1);
}

sub on_mouse_button_up {
    my $self = shift;
    return unless $self->is_pressed;
    my $t = !$self->is_toggled;
    $self->is_toggled($t);
    $self->depress;
    $self->command->($self->target, $t) if $self->command;
}

sub on_mouse_leave { shift->depress }

sub depress {
    my $self = shift;
    return unless $self->is_pressed;
    my $t = $self->is_toggled;
    $self->_set_button_depth($t? -1: -3);
    $self->is_pressed(0);
}

1;

__END__

UI state:
    2 - pressed hard
    1 - pressed
    0 - not pressed

UI state/toggle state    event    UI state/toggle state

       0/0               down              2/0
       2/0                up               1/1
       1/1               down              2/1
       2/1                up               0/0
       2/0               leave             0/0
       2/1               leave             0/1
        
