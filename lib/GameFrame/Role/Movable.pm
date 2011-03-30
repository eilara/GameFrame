package GameFrame::Role::Movable;

use Moose::Role;
use MooseX::Types::Moose qw(Num);
use GameFrame::Time;

# velocity in pixels per second
has v => (is => 'rw', isa => Num, required => 1, default => 100);

with 'GameFrame::Role::Positionable';

sub move {
    my $self = shift;
    my %args = @_;
    GameFrame::Time::move
        xy   => sub { $self->xy(@_) },
        v    => sub { $self->v },
        to   => $args{to},
        wild => $args{wild},
}

# returns by how many pixels per second did we slow
sub slow {
    my ($self, $percent) = @_;
    my $v = $self->v;
    my $delta_v = $v * ($percent/100);
    $self->v($v - $delta_v);
    return $delta_v;
}

sub haste {
    my ($self, $delta_v) = @_;
    $self->v($self->v + $delta_v);
}

1;


