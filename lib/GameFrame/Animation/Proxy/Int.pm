package GameFrame::Animation::Proxy::Int;

use Moose;
use Scalar::Util qw(weaken);

# TODO add distinct int optimization

extends 'GameFrame::Animation::Proxy';

around build_set_value_cb => sub {
    my ($orig, $self) = @_;
    my $parent = $orig->($self);
    weaken $self;
    return sub {
        my $value = shift;
        my $round = int $value;
        $parent->($round);
    };
};

1;
