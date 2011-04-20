package GameFrame::Widget::Button;

# a rectangular button

use Moose;
use MooseX::Types::Moose qw(Bool CodeRef);

has is_pressed => (is => 'rw', isa => Bool, default => 0);
has is_enabled => (is => 'rw', isa => Bool, default => 1,
                   trigger => sub { shift->is_enabled_trigger });

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
        file      => (delete($args{icon}) || die 'no icon given'),
        size      => [$args{w}, $args{h}],
        sequences => { default => [[0,0]], disabled => [[1,0]]},
    };
    my $size = $args{size};
    ($args{w}, $args{h}) = @$size if $size;
    $args{image}->{size} ||= [$args{w}, $args{h}];
    return $class->$orig(%args);
};

sub is_disabled { !shift->is_enabled }
sub enable      { shift->is_enabled(1) }
sub disable     { shift->is_enabled(0) }

sub is_enabled_trigger {
    my $self = shift;
    $self->sequence_animation($self->is_enabled? 'default': 'disabled');
}

sub on_mouse_button_down { shift->press }

sub on_mouse_button_up {
    my $self = shift;
    return unless $self->depress;
    $self->command->($self->target) if $self->command;
}

sub on_mouse_leave { shift->depress }

sub press {
    my $self = shift;
    return 0 if $self->is_pressed || $self->is_disabled;
    $self->_set_button_depth(2);
    $self->is_pressed(1);
    return 1;
}

sub depress {
    my $self = shift;
    return 0 unless $self->is_pressed;
    $self->_set_button_depth(-2);
    $self->is_pressed(0);
    return 1;
}

sub _set_button_depth {
    my ($self, $depth) = @_;
    my $new_y = $self->y + $depth;
    $self->y($new_y);
    $self->bg_y($new_y);
}

1;
