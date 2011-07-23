package GameFrame::Role::Living;

# a role for game objects that have hit points, can be hit, and then die
# override on_hit to get a notification each time the object is hit
# override on_death to get one when the game object dies

use Moose::Role;
use MooseX::Types::Moose qw(Bool Num);
use aliased 'Coro::Signal';

has is_alive => (
    is       => 'rw',
    isa      => Bool,
    default  => 1,
);

has start_hp => (
    is       => 'ro',
    isa      => Num,
    required => 1,
);

has hp => (
    is       => 'rw',
    isa      => Num,
    lazy     => 1,
    default  => sub { shift->start_hp },
);

has death_signal => (
    is      => 'ro',
    default => sub { Signal->new },
    handles => {
        _wait_for_death => 'wait',
        broadcast_death => 'broadcast',
    },
);

sub on_hit   {}
sub on_death {}

sub accept_death {
    my $self = shift;
    $self->hp(0);
    $self->is_alive(0);
    $self->on_death;
    $self->broadcast_death;
}

sub wait_for_death {
    my $self = shift;
    return unless $self->is_alive;
    $self->_wait_for_death;
}

sub hit {
    my ($self, $damage) = @_;
    return unless $self->is_alive;
    my $hp = $self->hp - $damage;
    $hp = 0 if $hp < 0;
    $self->hp($hp);
    $self->on_hit;
    $self->accept_death if $hp == 0;
}

sub hp_ratio {
    my $self = shift;
    return $self->hp / $self->start_hp;
}
 
1;
