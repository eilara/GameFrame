package GameFrame::Role::AnimatedSprite;

# the animated sprite role

use Moose::Role;
use MooseX::Types::Moose qw(Str ArrayRef HashRef);

has sequences =>
    (is => 'ro', required => 1, isa => HashRef[ArrayRef[ArrayRef]]);

has _sequence => (is => 'rw', isa => Str, lazy_build => 1);

with 'GameFrame::Role::Sprite';

sub _build__sequence { (keys %{ shift->sequences })[0] }

around _build_sprite => sub {
    my ($orig, $self) = @_;
    return $self->build_sdl_animated_sprite(
        $self->size,
        $self->sequences,
        $self->_sequence,
    );
};

sub sequence {
    my ($self, $value) = @_;
    return $self->_sequence if @_ == 1;
    $self->_sequence($value);
print "SETTING:$value\n";
    $self->sprite->sequence($value);
}

# TODO patch SDLx to allow setting frame num
# TODO horrible things will happen if you provite out of bound frames here
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

       $self->animate_sprite(
            sequence => $self->sequence,
            frames   => 4,
            sleep    => 0.2,
        );

sub animate_sprite {
    my ($self, %args) = @_;
    my ($sequence, $frames, $sleep) = map { $args{$_} } qw(sequence frames sleep);
    interval
        times => $frames,
        sleep => $sleep,
        step  => sub { $self->next_animation },
        start => sub { $self->sequence_animation($sequence) };
}


