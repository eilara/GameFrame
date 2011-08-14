package GameFrame::CamelDefense::Wave;

use Moose;

with qw(
    GameFrame::Role::Container::Simple
    GameFrame::Role::Active
    GameFrame::Role::Spawner
);

has [qw(duration waves)] => (is => 'ro', required => 1);

sub start {
    my $self = shift;
    $self->spawn(duration => $self->duration, waves => $self->waves);
}

1;

