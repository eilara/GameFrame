package GameFrame::Animation::Proxy::SpritePosition;

use Moose;
use Data::Alias;
use GameFrame::Util::Vectors;

extends 'GameFrame::Animation::Proxy';

sub get_init_value {
    my $self = shift;
    return V(@{ $self->target->xy_vec });
}

sub build_set_value_cb {
    my $self           = shift;
    my $target         = $self->target;
    alias my $xy       = $target->xy_vec;
    alias my $sprite   = $target->sprite;
    alias my $size     = $target->_size;
    my $compute_actual = $target->is_centered?
        sub {
            my $v = shift;
            return [$v->[0] - $size->[0]/2, $v->[1] - $size->[1]/2];
        }:
        sub { shift };
    return sub {
        my $value = shift;
        $xy->[0] = $value->[0];
        $xy->[1] = $value->[1];
        my $actual = $compute_actual->($value);
        $sprite->x($actual->[0]);
        $sprite->y($actual->[1]);
    };
}

1;
