package GameFrame::Role::Scoreable;

# shows a score counter and keeps score

use Moose::Role;
use MooseX::Types::Moose qw(Num ArrayRef);

with 'GameFrame::Role::Paintable';

has score => (
    is       => 'rw',
    isa      => Num,
    default  => 0,
);

has score_xy => (
    is       => 'ro',
    isa      => ArrayRef[Num],
    default  => sub { [600, 20] },
);

sub add_to_score {
    my ($self, $add) = @_;
    $self->score( $self->score + $add );
}

after paint => sub {
    my $self = shift;
    $self->draw_gfx_text($self->score_xy, 0xFFFF00FF, $self->score);
};

1;
