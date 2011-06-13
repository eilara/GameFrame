package GameFrame::Animation::Cycle::Duration;

use Moose;
use Scalar::Util qw(weaken);
use MooseX::Types::Moose qw(Num);

has duration => (is => 'ro', required => 1, isa => Num);

sub is_cycle_complete {
    my ($self, $elapsed) = @_;
    return $elapsed >= $self->duration? 1: 0;
}

1;
