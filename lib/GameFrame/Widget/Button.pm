package GameFrame::Widget::Button;

# a rectangular button

use Moose;
use MooseX::Types::Moose qw(Bool CodeRef);

has is_enabled => (is => 'rw', isa => Bool, default => 1);
has is_pressed => (is => 'rw', isa => Bool, default => 0);

has target  => (is => 'ro', weak_ref => 1);
has command => (is => 'ro', isa => CodeRef);

with qw(
    GameFrame::Role::AnimatedSprite
    GameFrame::Role::Event::Sink::Rectangular
    GameFrame::Role::BackgroundImage
);

# inject image file name, sizes and default sequence for button
around BUILDARGS => sub {
    my ($orig, $class, %args) = @_;
    $args{image} = {
        file      => delete $args{icon} || die 'no icon given',
        size      => [$args{w}, $args{h}],
        sequences => { default => [[0,0]], disabled => [[1,0]]},
    };
    my $size = $args{size};
    ($args{w}, $args{h}) = @$size if $size;
    $args{image}->{size} ||= [$args{w}, $args{h}];
    return $class->$orig(%args);
};

sub on_mouse_button_down {
    my $self = shift;
    return if $self->is_pressed;
    my $new_y = $self->y + 2;
    $self->y($new_y);
    $self->bg_y($new_y);
    $self->is_pressed(1);
}

sub on_mouse_button_up {
    my $self = shift;
    return unless $self->is_pressed;
    $self->_mouse_leave;
    $self->command->($self->target) if $self->command;
}

sub on_mouse_leave { shift->_mouse_leave }

sub _mouse_leave {
    my $self = shift;
    return unless $self->is_pressed;
    my $new_y = $self->y - 2;
    $self->y($new_y);
    $self->bg_y($new_y);
    $self->is_pressed(0);
}

1;

