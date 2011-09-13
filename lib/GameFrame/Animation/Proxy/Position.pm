package GameFrame::Animation::Proxy::Position;

use Moose;
use Scalar::Util qw(weaken);
use Data::Alias;
use GameFrame::Util::Vectors;

extends 'GameFrame::Animation::Proxy';

sub get_init_value {
    my $self = shift;
    return V(@{ $self->target->xy_vec });
}

sub build_set_value_cb {
    my $self = shift;
    weaken $self;
    alias my $target = $self->target;
    return sub {
        my $value = shift;
        $target->xy($value);
    };
}

1;
