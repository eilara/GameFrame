package GameFrame::Role::Living;

# a role for game objects that have hit points, can be hit, and then die
# override on_hit to get a notification each time the object is hit
# override on_death to get one when the game object dies

use Moose::Role;
use MooseX::Types::Moose qw(Bool Num);

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

sub on_hit   {}
sub on_death {}

sub hit {
    my ($self, $damage) = @_;
    return unless $self->is_alive;
    my $hp = $self->hp - $damage;
    $hp = 0 if $hp < 0;
    $self->hp($hp);
    $self->on_hit;
    if ($hp == 0) {
        $self->is_alive(0);
        $self->on_death;
    }
}

sub hp_ratio {
    my $self = shift;
    return $self->hp / $self->start_hp;
}
 
1;
