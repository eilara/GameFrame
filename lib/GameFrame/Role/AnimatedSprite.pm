package GameFrame::Role::AnimatedSprite;

# the animated sprite role

use Moose::Role;
use MooseX::Types::Moose qw(Str ArrayRef HashRef);
use aliased 'GameFrame::Animation::Proxy::Int' => 'IntProxy';

has sequences =>
    (is => 'ro', required => 1, isa => HashRef[ArrayRef[ArrayRef]]);

has _sequence => (is => 'rw', isa => Str, lazy_build => 1);

with qw(
    GameFrame::Role::Sprite
    GameFrame::Role::Animated
);

# pick a random default sequence if none given
sub _build__sequence { (keys %{ shift->sequences })[0] }

around _build_sprite => sub {
    my ($orig, $self) = @_;
    return $self->build_sdl_animated_sprite(
        $self->size,
        $self->sequences,
        $self->_sequence,
    );
};

sub animate_sprite {
    my ($self, %args) = @_;

    my $sequence = delete $args{sequence};
    $self->sequence($sequence) if $sequence;

    # TODO animation should do one tick on last value!
    if ($args{to}) { $args{to}           += 0.99 }
    else           { $args{from_to}->[1] += 0.99 }

    # TODO animation should be stored in a field for animation control
    $self->animate({
        attribute   => 'current_frame',
        proxy_class => IntProxy,
        %args,
    });
}

sub sequence {
    my ($self, $value) = @_;
    return $self->_sequence if @_ == 1;
    my $current_frame = $self->current_frame; # save it because setting 
                                              # sequence resets it
    $self->_sequence($value);
    my $sprite = $self->sprite;
    $sprite->sequence($value);

    $sprite->next for 2..$current_frame; # advance to the correct frame
}

# TODO patch SDLx to allow setting frame num
# TODO horrible things will happen if you provide out of bound frames here
# TODO apply same accuracy fixes as in spawner
sub current_frame {
    my ($self, $new_frame) = @_;
    my $sprite = $self->sprite;
    my $current_frame = $sprite->current_frame;
    return $current_frame if @_ == 1;

    return if $new_frame == $current_frame;
    my $dir = $new_frame > $current_frame? 'next': 'previous';
    $sprite->$dir for 1 .. abs($new_frame - $current_frame);
}

around BUILDARGS => sub {
    my ($orig, $class, %args) = @_;

    if (my $sequence = delete $args{sequence})
        { $args{_sequence} = $sequence }

    return $class->$orig(%args);
};

1;

__END__

